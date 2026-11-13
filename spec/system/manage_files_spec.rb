# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Manage files' do
  include_context 'with show page object client'

  let(:druid) { 'druid:bc123df4567' }
  let(:title) { 'My title' }

  let(:cocina_object) { build(:dro_with_metadata, id: druid) }
  let!(:user) { create(:user) }

  let(:object_lock) { 'abc123' }

  # The initial version is open, so no version description is requested.
  let(:version_status) do
    Dor::Services::Client::ObjectVersion::VersionStatus.new(versionId: 1, open: true, openable: false,
                                                            closeable: true, assembling: false,
                                                            accessioning: false, discardable: false,
                                                            versionDescription: 'Initial version')
  end

  before do
    create(:permission, :read_unrestricted, workgroup: user.groups.first)
    create(:permission, :edit, workgroup: user.groups.first, target_druid: druid)

    sign_in(user)

    allow(Sdr::Repository).to receive_messages(find: cocina_object,
                                               find_solr: build(:solr_item, druid:, title:))
    allow(Sdr::Repository).to receive(:update) { |cocina_object:, **| cocina_object.new(lock: 'updated-lock') }
    allow(StageFilesJob).to receive(:perform_later)
    allow(Sdr::WorkflowService).to receive(:workflows_for).and_return([])
    # The wait page refreshes quickly, so that it shows the next step soon after the job has been performed, but not
    # so often that a refresh is still pending (Turbo debounces them) once the next step has been shown.
    allow(Settings.reload_intervals).to receive(:mount_discovery).and_return(500)
  end

  def mutable_content
    Content.find_by!(druid:, immutable: false)
  end

  def expect_step(label)
    expect(page).to have_css('li[aria-current="step"]', text: label)
  end

  def visit_files_step
    visit "/contents/#{druid}/edit"
    click_button 'Next'
    expect_step('Add and edit files')
  end

  def upload_file(filename)
    attach_file(nil, Rails.root.join("spec/fixtures/files/#{filename}"), class: 'dz-hidden-input', make_visible: true)
    expect(page).to have_css('tbody th', exact_text: File.basename(filename))
  end

  # Leaves the add and edit files step (or structures again from the structure step), performing the structuring job.
  def structure_files(button: 'Next', append: false)
    click_button button
    expect(page).to have_css('[role="status"]', text: 'Structuring files...')
    expect_step('Structure files')

    StructureFilesJob.perform_now(content: mutable_content, append:)

    expect(page).to have_css('h3', text: /\AResources/)
  end

  def deposit
    click_button 'Next'
    expect_step('Deposit')
    click_button 'Deposit'
  end

  it 'displays the object title and the steps, opening on the item details step', :rack_test do
    visit "/contents/#{druid}/edit"

    expect(page).to have_css('h1', text: 'Manage files and structure')
    expect(page).to have_css('p', text: title)
    expect(page).to have_css('ol[aria-label="Manage files progress"] li', count: 4)
    expect_step('Item details')
    expect(page).to have_no_css('[role="tab"]')
  end

  context 'with a structured file' do
    let(:cocina_object) { build(:dro_with_metadata, id: druid).new(access: { view: 'world', download: 'world' }) }
    let!(:content) { create(:content, :mutable, druid:, lock: cocina_object.lock) }
    let!(:content_file) do
      create(:content_file, content_file_set: create(:content_file_set, content:, file_set_type: 'page'),
                            content_file_binary: create(:content_file_binary, content:, filepath: 'page_0001.png',
                                                                              mime_type: 'image/png'))
    end

    it 'updates the item details, moves through the steps, and deposits' do
      visit "/contents/#{druid}/edit"

      expect(page).to have_select('Viewing direction', disabled: true, visible: :hidden)
      # The default content type cannot be OCRed.
      expect(page).to have_field('Yes', type: 'radio', disabled: true, visible: :hidden)
      expect(page).to have_no_css('label', text: 'Search for a language')

      select 'book', from: 'Content type'
      select 'right-to-left', from: 'Viewing direction'

      expect(page).to have_field('Yes', type: 'radio', disabled: false)
      # The languages remain hidden until OCR is requested.
      expect(page).to have_no_css('label', text: 'Search for a language')

      choose 'Yes'

      expect(find_multi_select('Search for a language')[:class]).not_to include('disabled')
      select_multi_option('English', from: 'Search for a language')
      # Closes the language dropdown, which would otherwise cover the buttons.
      find('h2', text: 'Item details').click

      click_button 'Next'
      expect_step('Add and edit files')
      # Every file is already in a resource, so the files are not structured again.
      click_button 'Next'
      expect_step('Structure files')
      expect(page).to have_css('h3', text: 'Resources (1)')
      expect(page).to have_no_css('.alert-info')

      deposit

      expect(page).to have_current_path("/objects/#{druid}")

      # The access settings, though collapsed, are submitted.
      expect(Sdr::Repository).to have_received(:update)
        .with(cocina_object: having_attributes(type: Cocina::Models::ObjectType.book,
                                               access: having_attributes(view: 'world', download: 'world'),
                                               structural: having_attributes(
                                                 hasMemberOrders: [having_attributes(viewingDirection: 'right-to-left')]
                                               )),
              user_name: user.sunetid, description: nil)
      expect(content.reload).to have_attributes(perform_ocr: true, ocr_languages: ['English'])
      expect(StageFilesJob).to have_received(:perform_later).with(content:, accession: true, user:)
    end

    it 'overwrites the file access, which is required while dark' do
      visit "/contents/#{druid}/edit"

      click_on 'Access settings'

      expect(page).to have_field('Overwrite file-level rights', checked: true, disabled: false)

      within_fieldset('Access settings without embargo') do
        select 'Dark', from: 'View access'
      end
      expect(page).to have_field('Overwrite file-level rights', checked: true, disabled: true)

      within_fieldset('Access settings without embargo') do
        select 'Stanford', from: 'View access'
        select 'Stanford', from: 'Download access'
      end
      expect(page).to have_field('Overwrite file-level rights', checked: true, disabled: false)

      click_on 'Save as draft'

      expect(page).to have_current_path("/objects/#{druid}")
      expect(content_file.reload).to have_attributes(view: 'stanford', download: 'stanford')
      expect(StageFilesJob).to have_received(:perform_later).with(content:, accession: false, user:)
    end
  end

  it 'adds an embargo from the item details' do
    visit "/contents/#{druid}/edit"

    # The access settings are collapsed until expanded.
    expect(page).to have_css('button[aria-expanded="false"]', text: 'Access settings')
    expect(page).to have_no_field('Without embargo', visible: :visible)
    click_on 'Access settings'
    expect(page).to have_css('button[aria-expanded="true"]', text: 'Access settings')

    expect(page).to have_field('Without embargo', type: 'radio', checked: true, visible: :all)
    expect(page).to have_no_css('legend', text: 'Access settings during embargo')

    choose 'With embargo', allow_label_click: true
    fill_in 'When will this embargo end?', with: Date.new(2040, 6, 1)
    within_fieldset('Access settings during embargo') do
      select 'Dark', from: 'View access'
    end
    within_fieldset('Access settings once embargo ends') do
      select 'Stanford', from: 'View access'
    end

    click_on 'Save as draft'

    expect(page).to have_current_path("/objects/#{druid}")
    expect(Sdr::Repository).to have_received(:update)
      .with(cocina_object: having_attributes(
        access: having_attributes(view: 'dark',
                                  embargo: having_attributes(releaseDate: Time.zone.parse('2040-06-01'),
                                                             view: 'stanford'))
      ),
            user_name: user.sunetid, description: nil)
  end

  it 'expands the access settings when redisplaying the step with an error in them' do
    visit "/contents/#{druid}/edit"

    click_on 'Access settings'
    choose 'With embargo', allow_label_click: true

    click_button 'Next'

    expect_step('Item details')
    expect(page).to have_css('button[aria-expanded="true"]', text: 'Access settings')
    expect(page).to have_css('.invalid-feedback', text: "can't be blank")
    expect(Sdr::Repository).not_to have_received(:update)
  end

  it 'moves between the steps with next and previous, keeping the item details' do
    visit "/contents/#{druid}/edit"

    expect_step('Item details')
    expect(page).to have_no_button('Previous')
    select 'book', from: 'Content type'

    click_button 'Next'
    expect_step('Add and edit files')
    expect(page).to have_css('li.progress-stepper-step-completed', text: 'Item details')

    click_button 'Previous'
    expect_step('Item details')
    expect(page).to have_select('Content type', selected: 'book')
    expect(Sdr::Repository).not_to have_received(:update)
  end

  it 'saves as a draft from a step other than deposit' do
    visit "/contents/#{druid}/edit"

    click_button 'Save as draft'

    expect(page).to have_current_path("/objects/#{druid}")
    expect(StageFilesJob).to have_received(:perform_later).with(content: mutable_content, accession: false, user:)
  end

  context 'when discarding the draft' do
    let(:cocina_object) { build(:dro_with_metadata, id: druid, version: 2) }
    let(:version_status) do
      Dor::Services::Client::ObjectVersion::VersionStatus.new(versionId: 2, open: true, openable: false,
                                                              closeable: true, assembling: false,
                                                              accessioning: false, discardable: true,
                                                              versionDescription: 'Added files')
    end

    before do
      allow(version_client).to receive(:discard)
    end

    it 'confirms, discards the version and the mutable content, and returns to the object page' do
      visit_files_step
      # The loaded files frame shows that Turbo is running, so it handles the click.
      expect(page).to have_css("turbo-frame[id^='show_content_'] p", text: 'No files yet')

      click_and_accept_confirm(/\ADiscard this draft\?/, find_link('Discard draft'))

      expect(page).to have_current_path("/objects/#{druid}")
      expect(page).to have_toast('Draft discarded.')
      expect(version_client).to have_received(:discard)
      expect(Content.exists?(druid:, immutable: false)).to be false
    end
  end

  context 'when canceling' do
    it 'confirms, discards the unsaved changes, and returns to the object page' do
      visit_files_step

      upload_file('dropzone_upload.txt')

      click_and_accept_confirm('Discard unsaved changes to files?', find_link('Cancel'))

      expect(page).to have_current_path("/objects/#{druid}")
      expect(page).to have_toast('Unsaved changes to files discarded')

      # Managing files starts again from the first step.
      visit "/contents/#{druid}/edit"
      expect_step('Item details')
      click_button 'Next'

      expect(page).to have_css("turbo-frame[id^='show_content_'] p", text: 'No files yet')
    end
  end

  it 'warns about embedded text when running OCR on a document' do
    warning = 'Do not run OCR for files that already have embedded text.'

    visit "/contents/#{druid}/edit"

    select 'document', from: 'Content type'

    expect(page).to have_no_text(warning)

    choose 'Yes'

    expect(page).to have_text(warning)

    # The warning is specific to documents.
    select 'book', from: 'Content type'

    expect(page).to have_no_text(warning)
  end

  it 'hides the OCR options again when the content type can no longer be OCRed' do
    visit "/contents/#{druid}/edit"

    select 'book', from: 'Content type'
    choose 'Yes'
    select_multi_option('English', from: 'Search for a language')

    select 'map', from: 'Content type'

    expect(page).to have_field('Yes', type: 'radio', disabled: true, visible: :hidden)
    expect(page).to have_no_css('label', text: 'Search for a language')
    expect(find('select[name$="[ocr_languages][]"]', visible: :all)).to be_disabled
  end

  context 'when depositing stopped with a process in error' do
    let(:cocina_object) { build(:dro_with_metadata, id: druid, type: Cocina::Models::ObjectType.book) }
    let(:version_status) do
      Dor::Services::Client::ObjectVersion::VersionStatus.new(versionId: 1, open: true, openable: false,
                                                              closeable: false, assembling: true,
                                                              accessioning: false, discardable: false,
                                                              versionDescription: 'Initial version')
    end
    let(:workflows_xml) do
      <<~XML
        <workflows objectId="#{druid}">
          <workflow objectId="#{druid}" id="assemblyWF">
            <process version="1" status="error" name="jp2-create"/>
            <process version="1" status="waiting" name="accessioning-initiate"/>
          </workflow>
        </workflows>
      XML
    end

    before do
      create(:content, :mutable, druid:, lock: cocina_object.lock, perform_ocr: true, ocr_languages: ['English'])
      allow(object_client).to receive(:workflows)
        .and_return(Dor::Services::Response::Workflows.new(xml: Nokogiri::XML(workflows_xml)))
    end

    it 'does not offer the text extraction settings or depositing', :rack_test do
      visit "/contents/#{druid}/edit"

      expect(page).to have_field('Content type')
      expect(page).to have_no_text(I18n.t('edit.items.fields.perform_ocr.label'))
      expect(page).to have_no_text('Search for a language')

      mutable_content.update!(step: 'deposit')
      visit "/contents/#{druid}/edit"

      expect_step('Deposit')
      expect(page).to have_no_button('Deposit', type: 'submit')
      expect(page).to have_button('Save as draft')
    end
  end

  it 'shows the speech to text question in place of the OCR question for media' do
    visit "/contents/#{druid}/edit"

    select 'book', from: 'Content type'

    expect(page).to have_css('legend', text: 'Run OCR?')
    expect(page).to have_no_css('legend', text: 'Do you want to auto-generate captions or transcripts for the media?')

    select 'media', from: 'Content type'

    expect(page).to have_css('legend', text: 'Do you want to auto-generate captions or transcripts for the media?')
    expect(page).to have_no_css('legend', text: 'Run OCR?')
    expect(find('input[name$="[perform_ocr]"][value="true"]', visible: :all)).to be_disabled
    expect(find('input[name$="[perform_speech_to_text]"][value="true"]')).not_to be_disabled
  end

  context 'when no files have been uploaded yet' do
    it 'reports that there are no files and does not allow proceeding' do
      visit_files_step

      within("turbo-frame[id^='show_content_']") do
        expect(page).to have_css('p', text: 'No files yet')
        expect(page).to have_no_css('tbody tr')
      end

      expect(page).to have_button('Next', disabled: true)
      expect(page).to have_text('Add at least one file to continue.')
    end
  end

  context 'when a file has been uploaded' do
    it 'structures the files, showing the model used, and deposits' do
      visit_files_step

      upload_file('dropzone_upload.txt')

      content = mutable_content
      content_file_binary = content.content_file_binaries.sole
      expect(content_file_binary).to have_attributes(filepath: 'dropzone_upload.txt', file_location: 'attached')
      expect(content_file_binary.file).to be_attached
      expect(content.content_file_sets).to be_empty
      expect(page).to have_button('Next', disabled: false)
      expect(page).to have_no_text('Add at least one file to continue.')

      structure_files

      expect(page).to have_css('.alert-info', text: 'Files were structured with the File (resource per file) model.')
      expect(page).to have_css('p', text: 'Strategy for structuring: File (resource per file)')
      expect(page).to have_no_text('Reasons for not using')
      expect(page).to have_css('h3', text: 'Resources (1)')

      content_file_set = content.content_file_sets.sole
      expect(content_file_set).to have_attributes(file_set_type: 'file')
      expect(content_file_set.content_files.sole.content_file_binary).to eq(content_file_binary)

      deposit

      expect(page).to have_current_path("/objects/#{druid}")
      expect(StageFilesJob).to have_received(:perform_later).with(content:, accession: true, user:)
    end
  end

  context 'when the upload fails on the server' do
    it 'shows a message for the status rather than the error page' do
      visit_files_step

      # The content is gone (e.g., the draft was discarded in another tab), so the upload responds with a 404 page.
      mutable_content.destroy!

      expect(page).to have_css('#file-dropzone [role="alert"]', visible: :all)
      attach_file(nil, Rails.root.join('spec/fixtures/files/dropzone_upload.txt'), class: 'dz-hidden-input',
                                                                                   make_visible: true)

      # The alert region is present before the error is added, so the error is announced.
      expect(page).to have_css('#file-dropzone [role="alert"] li',
                               exact_text: 'dropzone_upload.txt: Upload failed (server error 404). Try again.')
    end
  end

  context 'when access is selected before structuring' do
    let(:cocina_object) { build(:dro_with_metadata, id: druid).new(access: { view: 'world', download: 'world' }) }

    it 'structures the files with the selected access' do
      visit "/contents/#{druid}/edit"

      click_on 'Access settings'
      within_fieldset('Access settings without embargo') do
        select 'Dark', from: 'View access'
      end
      click_button 'Next'

      upload_file('dropzone_upload.txt')
      structure_files

      expect(mutable_content.content_files.sole)
        .to have_attributes(view: 'dark', download: 'none', shelve: false, publish: false)

      click_button 'Previous'
      click_button 'Previous'
      expect_step('Item details')
      click_on 'Access settings'
      choose 'With embargo', allow_label_click: true
      fill_in 'When will this embargo end?', with: Date.new(2040, 6, 1)
      within_fieldset('Access settings during embargo') do
        select 'Stanford', from: 'View access'
        select 'Stanford', from: 'Download access'
      end
      within_fieldset('Access settings once embargo ends') do
        select 'World', from: 'View access'
      end
      click_button 'Next'
      click_button 'Next'
      expect_step('Structure files')

      structure_files(button: 'Clear and structure files again')

      # The files have the access during the embargo; releasing the embargo updates them.
      expect(mutable_content.content_files.sole)
        .to have_attributes(view: 'stanford', download: 'stanford', shelve: true, publish: true)
    end
  end

  context 'when a file has been uploaded but not added to the structure' do
    it 'disables saving until the files have been added to the structure' do
      visit_files_step

      upload_file('dropzone_upload.txt')

      expect(page).to have_button('Save as draft', disabled: true)

      structure_files

      expect(page).to have_button('Save as draft', disabled: false)
    end
  end

  context 'when a file is uploading' do
    def dispatch_dropzone_event(name)
      page.execute_script("document.getElementById('file-dropzone')" \
                          ".dispatchEvent(new CustomEvent('dropzone:#{name}', { bubbles: true }))")
    end

    it 'disables actions until the upload finishes' do
      visit_files_step

      upload_file('dropzone_upload.txt')

      # Simulating the upload, since an actual upload finishes too quickly to observe.
      dispatch_dropzone_event('upload-start')

      expect(page).to have_button('Delete dropzone_upload.txt', disabled: true)
      expect(page).to have_field('Select files from mount', type: 'radio', disabled: true)
      expect(page).to have_button('Next', disabled: true)
      expect(page).to have_button('Previous', disabled: true)
      expect(page).to have_link('Cancel', class: 'disabled')

      dispatch_dropzone_event('upload-end')

      expect(page).to have_button('Delete dropzone_upload.txt', disabled: false)
      expect(page).to have_field('Select files from mount', type: 'radio', disabled: false)
      expect(page).to have_button('Next', disabled: false)
      expect(page).to have_no_css('a.disabled', text: 'Cancel')
    end

    it 'disables actions rendered while uploading' do
      visit_files_step

      upload_file('dropzone_upload.txt')

      dispatch_dropzone_event('upload-start')
      expect(page).to have_button('Delete dropzone_upload.txt', disabled: true)

      # For example, an upload finishing reloads the files section.
      page.execute_script("document.querySelector('turbo-frame[id^=\"show_content_\"]').reload()")

      expect(page).to have_button('Delete dropzone_upload.txt', disabled: true)
    end
  end

  context 'when the object is a book with images' do
    let(:cocina_object) do
      build(:dro_with_metadata, id: druid, type: Cocina::Models::ObjectType.book)
        .new(access: { view: 'world', download: 'world' })
    end

    it 'structures the book with a file set per page' do
      visit_files_step

      upload_file('page_0001.png')
      structure_files

      expect(page).to have_css('.alert-info', text: 'Files were structured with the Book (resource per page) model.')
      expect(mutable_content.content_file_sets.sole).to have_attributes(file_set_type: 'page', label: 'Page 1')
    end
  end

  context 'when the content type is changed to book' do
    let(:cocina_object) do
      build(:dro_with_metadata, id: druid).new(access: { view: 'world', download: 'world' })
    end

    it 'structures the files with the populator for the selected content type' do
      visit "/contents/#{druid}/edit"

      select 'book', from: 'Content type'
      click_button 'Next'

      upload_file('page_0001.png')
      structure_files

      expect(page).to have_css('.alert-info', text: 'Files were structured with the Book (resource per page) model.')
      expect(page).to have_css('p', text: 'Strategy for structuring: Book (resource per page)')
      expect(mutable_content.content_file_sets.sole).to have_attributes(file_set_type: 'page', label: 'Page 1')
    end
  end

  context 'when the object is a book that cannot be structured as a book' do
    let(:cocina_object) { build(:dro_with_metadata, id: druid, type: Cocina::Models::ObjectType.book) }

    it 'falls back to the default strategy and explains why' do
      visit_files_step

      upload_file('dropzone_upload.txt')
      structure_files

      # The content warnings are also a warning alert.
      within('.alert-warning', text: 'Files were structured with') do
        expect(page).to have_text('Files were structured with the Default (resource per file) model.')
        expect(page).to have_text('The Book (resource per page) model was not used because:')
        expect(page).to have_css('li', text: 'there are no image files')
      end
      expect(page).to have_css('p', text: 'Strategy for structuring: Default (resource per file)')
      expect(page).to have_text('Reasons for not using Book (resource per page)')
    end
  end

  context 'when depositing a book whose content is invalid for a book' do
    # A dark object's content errors are only warnings.
    let(:cocina_object) do
      build(:dro_with_metadata, id: druid, type: Cocina::Models::ObjectType.book)
        .new(access: { view: 'world', download: 'world' })
    end

    it 'shows the content errors on the structure step and does not deposit' do
      visit_files_step

      upload_file('dropzone_upload.txt')
      structure_files

      # Published files in a file resource are an error for a book.
      click_link('Edit resource 1')
      select 'file', from: 'Resource type'
      click_button 'Save'

      expect(page).to have_toast('Resource updated')
      expect(page).to have_css('.alert-danger', text: 'Content errors')

      deposit

      expect_step('Structure files')
      expect(page).to have_css('.invalid-feedback', text: 'Content errors must be fixed.')
      expect(page).to have_css('.alert-danger', text: 'Content errors')
      expect(StageFilesJob).not_to have_received(:perform_later)
    end
  end

  context 'when a book is made dark on the item details' do
    let(:cocina_object) do
      build(:dro_with_metadata, id: druid, type: Cocina::Models::ObjectType.book)
        .new(access: { view: 'world', download: 'world' })
    end
    let(:content) { mutable_content }

    before do
      content = create(:content, :mutable, druid:, lock: cocina_object.lock, step: 'structure')
      # Published files in a file resource are an error for a book.
      create(:content_file, content_file_set: create(:content_file_set, content:, file_set_type: 'file',
                                                                        label: 'File 1'),
                            content_file_binary: create(:content_file_binary, content:, filepath: 'page_0001.jp2',
                                                                              mime_type: 'image/jp2'),
                            view: 'world', download: 'world', publish: true, shelve: true, preserve: true)
    end

    it 'shows the content errors as warnings and deposits with the files made dark' do
      visit "/contents/#{druid}/edit"

      expect(page).to have_css('.alert-danger', text: 'has published files but is not a page or object resource')

      click_button 'Previous'
      expect_step('Add and edit files')
      # The structure step's content errors are not kept when moving to another step.
      expect(page).to have_no_css('.alert-danger')
      click_button 'Previous'
      click_on 'Access settings'
      within_fieldset('Access settings without embargo') do
        select 'Dark', from: 'View access'
      end
      click_button 'Next'
      click_button 'Next'
      expect_step('Structure files')

      # The file is still published, which is not an error, since depositing makes it dark.
      expect(page).to have_css('.alert-warning', text: 'has published files but is not a page or object resource')
      expect(page).to have_no_css('.alert-danger')

      deposit

      expect(page).to have_current_path("/objects/#{druid}")
      expect(content.content_files.sole).to have_attributes(view: 'dark', download: 'none', publish: false,
                                                            shelve: false)
      expect(StageFilesJob).to have_received(:perform_later).with(content:, accession: true, user:)
    end
  end

  context 'when a dark book has a published file' do
    let(:cocina_object) do
      build(:dro_with_metadata, id: druid, type: Cocina::Models::ObjectType.book)
        .new(access: { view: 'dark', download: 'none' })
    end
    let(:dark_file_error) do
      'Resource 1 (Page 1) file page_0001.jp2 must not be published or shelved because the object is dark.'
    end

    before do
      content = create(:content, :mutable, druid:, lock: cocina_object.lock)
      create(:content_file, content_file_set: create(:content_file_set, content:, file_set_type: 'page',
                                                                        label: 'Page 1'),
                            content_file_binary: create(:content_file_binary, content:, filepath: 'page_0001.jp2',
                                                                              mime_type: 'image/jp2'),
                            view: 'dark', download: 'none', publish: true, shelve: false)
    end

    def go_to_structure_step_with_view_access(view_access)
      within_fieldset('Access settings without embargo') do
        select view_access, from: 'View access'
        select view_access, from: 'Download access' unless view_access == 'Dark'
      end
      click_button 'Next'
      click_button 'Next'
      expect_step('Structure files')
    end

    it 'shows the file as a content error unless another access is selected, and does not deposit' do
      visit "/contents/#{druid}/edit"

      click_on 'Access settings'
      go_to_structure_step_with_view_access('World')
      expect(page).to have_css('h3', text: 'Resources (1)')
      expect(page).to have_no_text(dark_file_error)

      click_button 'Previous'
      click_button 'Previous'
      click_on 'Access settings'
      go_to_structure_step_with_view_access('Dark')
      expect(page).to have_css('.alert-danger li', text: dark_file_error)

      deposit

      expect_step('Structure files')
      expect(page).to have_css('.invalid-feedback', text: 'Content errors must be fixed.')
      expect(StageFilesJob).not_to have_received(:perform_later)
    end
  end

  context 'when the structure has been built and another file is uploaded' do
    let(:content) { mutable_content }

    # Builds the structure from one file, then returns to upload a second file that is not yet in the structure.
    def build_structure_then_upload_another_file
      visit_files_step

      upload_file('dropzone_upload.txt')
      structure_files

      click_button 'Previous'
      expect_step('Add and edit files')
      upload_file('dropzone_upload2.txt')
    end

    it 'appends the file to the structure when leaving the add and edit files step' do
      build_structure_then_upload_another_file

      original_content_file = content.content_files.sole

      structure_files(append: true)

      expect(page).to have_css('h3', text: 'Resources (2)')
      expect(content.content_file_sets.pluck(:position)).to eq([1, 2])
      expect(content.content_file_sets.first.content_files.sole).to eq(original_content_file)
      expect(content.content_file_sets.last.content_files.sole.filepath).to eq('dropzone_upload2.txt')
    end

    it 'rebuilds the structure' do
      build_structure_then_upload_another_file
      structure_files(append: true)

      original_content_file_set = content.content_file_sets.first
      original_content_file = original_content_file_set.content_files.sole

      structure_files(button: 'Clear and structure files again')

      expect(content.content_file_sets.pluck(:position)).to eq([1, 2])
      expect(ContentFileSet.exists?(original_content_file_set.id)).to be false
      expect(ContentFile.exists?(original_content_file.id)).to be false
      expect(content.content_files.map(&:filepath)).to eq(['dropzone_upload.txt', 'dropzone_upload2.txt'])
    end
  end

  context 'when uploading a structural CSV' do
    let(:content) { mutable_content }

    it 'updates the structure from the CSV' do
      visit_files_step

      upload_file('dropzone_upload.txt')
      structure_files

      csv_path = Rails.root.join('tmp/structure.csv')
      csv = CSV.parse(StructuralCsv::Export.as_csv(content:), headers: true)
      csv.each { |row| row['resource_label'] = 'New label' }
      File.write(csv_path, csv.to_csv)

      attach_file('Upload structural CSV', csv_path)
      click_button 'Upload'

      expect(page).to have_toast('Structure updated from CSV')
      expect_step('Structure files')
      expect(content.content_file_sets.reload.sole.label).to eq('New label')
    ensure
      FileUtils.rm_f(csv_path)
    end
  end

  context 'when editing a resource' do
    let(:content) { mutable_content }

    def build_structure_then_edit_resource
      visit_files_step

      upload_file('dropzone_upload.txt')
      structure_files

      click_link('Edit resource 1')
    end

    it 'updates the role of a file' do
      build_structure_then_edit_resource

      select_multi_option('transcription', from: 'Role')
      click_button 'Save'

      expect(page).to have_toast('Resource updated')
      expect(page).to have_css('td', text: 'Transcription')
      expect(content.content_files.sole.use).to eq('transcription')
    end

    it 'updates the role of a file to one that is not listed' do
      build_structure_then_edit_resource

      find_multi_select('Role').find('.ts-control input').set('supplement')
      find('.ts-dropdown .create', text: 'supplement').click
      click_button 'Save'

      expect(page).to have_toast('Resource updated')
      expect(content.content_files.sole.use).to eq('supplement')
    end

    it 'deletes the resource' do
      visit_files_step

      upload_file('dropzone_upload.txt')
      upload_file('dropzone_upload2.txt')
      structure_files

      expect(page).to have_css('h3', text: 'Resources (2)')

      click_and_accept_confirm('Delete resource 1 and its files?', find_button('Delete resource 1'))

      expect(page).to have_toast('Resource deleted')
      # The page is refreshed and the deleted file's binary is gone.
      expect(page).to have_css('h3', text: 'Resources (1)')
      expect(content.content_file_sets.size).to eq(1)
      expect(content.content_file_binaries.sole.filepath).to eq('dropzone_upload2.txt')
    end

    it 'moves a resource' do
      visit_files_step

      upload_file('dropzone_upload.txt')
      upload_file('dropzone_upload2.txt')
      structure_files

      expect(page).to have_no_button('Move resource 1 up')
      expect(page).to have_no_button('Move resource 2 down')

      click_button 'Move resource 2 up'

      expect(page).to have_toast('Resource moved')
      # The page is refreshed with the resources in their new order.
      # Matched in one selector so that Capybara retries while the page is refreshed.
      expect(page).to have_xpath("(//*[contains(@class, 'file-set-card')])[1]//td[contains(., 'dropzone_upload2.txt')]")
      expect(content.content_file_sets.map { |content_file_set| content_file_set.content_files.sole.filepath })
        .to eq(['dropzone_upload2.txt', 'dropzone_upload.txt'])
    end

    it 'deletes the resource when every file is removed' do
      build_structure_then_edit_resource

      content_file_binary = content.content_file_binaries.sole

      expect(page).to have_no_text('Saving will delete this resource.')
      click_button 'Remove dropzone_upload.txt'
      expect(page).to have_no_field('Role')
      expect(page).to have_css('[role="alert"]', text: 'Saving will delete this resource.')

      click_button 'Save'

      expect(page).to have_toast('Resource deleted')
      # The page is refreshed and the deleted file's binary is gone.
      expect(page).to have_css('p', text: 'No files.')
      expect(content.content_file_sets).to be_empty
      expect(ContentFileBinary.exists?(content_file_binary.id)).to be false
    end
  end

  context 'with files in folders' do
    let!(:content) { create(:content, :mutable, druid:, lock: cocina_object.lock, step: 'files') }

    before do
      ['root.txt', 'folder1/file1.txt', 'folder1/sub1/file2.txt', 'folder1/sub1/file3.txt'].each do |filepath|
        create(:content_file_binary, content:, filepath:, mime_type: 'text/plain')
      end
    end

    def file_row(filename)
      find('tbody tr[data-sdr-treegrid-role="file"]', text: filename)
    end

    def folder_row(folder_name)
      find('tbody tr[data-sdr-treegrid-role="folder"]', text: folder_name)
    end

    it 'expands and collapses the folders, keeping them expanded when the files are reloaded' do
      visit "/contents/#{druid}/edit"

      # Folders are collapsed, and only the first row is in the tab order.
      expect(page).to have_css('tbody th', exact_text: 'root.txt')
      expect(page).to have_css('tbody tr[tabindex="0"]', count: 1, text: 'root.txt')
      expect(folder_row('folder1')['aria-expanded']).to eq('false')
      expect(page).to have_no_css('tbody th', exact_text: 'file1.txt')

      folder_row('folder1').click
      expect(page).to have_css('tbody th', exact_text: 'file1.txt')
      expect(folder_row('sub1')['aria-expanded']).to eq('false')
      expect(page).to have_no_css('tbody th', exact_text: 'file2.txt')

      # Keyboard: down to sub1, right to expand it, right to its first file, left to sub1, left to collapse it.
      file_row('file1.txt').send_keys(:down)
      page.send_keys(:right)
      expect(page).to have_css('tbody th', exact_text: 'file2.txt')
      page.send_keys(:right)
      expect(page).to have_css('tbody tr[data-sdr-treegrid-role="file"]:focus', text: 'file2.txt')
      page.send_keys(:left)
      expect(page).to have_css('tbody tr[data-sdr-treegrid-role="folder"]:focus', text: 'sub1')
      page.send_keys(:left)
      expect(page).to have_no_css('tbody th', exact_text: 'file2.txt')

      click_button 'Expand all'
      expect(page).to have_css('tbody th', exact_text: 'file3.txt')
      click_button 'Collapse all'
      expect(page).to have_no_css('tbody th', exact_text: 'file1.txt')

      # Deleting a file reloads the files, with the expanded folders still expanded.
      folder_row('folder1').click
      folder_row('sub1').click
      click_button 'Delete folder1/sub1/file2.txt'

      expect(page).to have_toast('File deleted')
      expect(page).to have_no_css('tbody th', exact_text: 'file2.txt')
      expect(page).to have_css('tbody th', exact_text: 'file3.txt')
      expect(page).to have_css('tbody th', exact_text: 'file1.txt')
    end
  end

  context 'when deleting a file' do
    let(:content) { mutable_content }

    it 'deletes a file that has not been added to the structure without confirming' do
      visit_files_step

      upload_file('dropzone_upload.txt')
      expect(page).to have_css('h2', exact_text: 'Files (1)')

      click_button 'Delete dropzone_upload.txt'

      expect(page).to have_toast('File deleted')
      within("turbo-frame[id^='show_content_']") do
        expect(page).to have_css('p', text: 'No files yet')
        expect(page).to have_css('h2', exact_text: 'Files (0)')
      end
      expect(page).to have_button('Next', disabled: true)
      expect(content.content_file_binaries).to be_empty
    end

    it 'confirms and deletes the resource that deleting the file empties' do
      visit_files_step

      upload_file('dropzone_upload.txt')
      structure_files

      click_button 'Previous'
      click_and_accept_confirm('Deleting dropzone_upload.txt will also delete resource 1. Continue?',
                               find_button('Delete dropzone_upload.txt'))

      expect(page).to have_toast('File deleted')
      within("turbo-frame[id^='show_content_']") do
        expect(page).to have_css('p', text: 'No files yet')
      end
      expect(content.content_file_sets).to be_empty
      expect(content.content_file_binaries).to be_empty
    end
  end

  it 'hides the dropzone when using files from a mount' do
    visit_files_step

    expect(page).to have_css('#file-dropzone.dz-clickable:not(.opacity-50)')

    choose 'Select files from mount'

    expect(page).to have_css('#file-dropzone.opacity-50:not(.dz-clickable)', visible: :hidden)

    choose 'Select files from computer'

    expect(page).to have_css('#file-dropzone.dz-clickable:not(.opacity-50)')
    expect(page).to have_button('Select files to upload', disabled: false)
  end

  context 'when discovering files on a mount' do
    let(:mount_path) { Dir.mktmpdir(nil, Rails.root.join('tmp')) }

    before do
      FileUtils.mkdir_p(File.join(mount_path, 'folder'))
      FileUtils.cp(file_fixture('dropzone_upload.txt'), File.join(mount_path, 'folder/dropzone_upload.txt'))
    end

    after do
      FileUtils.rm_rf(mount_path)
    end

    it 'shows the wait page while discovering, then the discovered files' do
      visit_files_step

      choose 'Select files from mount'
      fill_in 'Mount path', with: mount_path
      click_button 'Discover files'

      expect(page).to have_css('[role="status"]', text: 'Discovering files...')
      expect_step('Add and edit files')
      expect(page).to have_no_button('Save as draft')

      content = mutable_content
      expect(content.mount_state).to eq('discovering')

      DiscoverFilesJob.perform_now(content:, mount_path:)

      expect(page).to have_css('tbody tr[data-sdr-treegrid-role="folder"]', text: 'folder')
      click_button 'Expand all'
      expect(page).to have_css('tbody th', exact_text: 'dropzone_upload.txt')
      expect(page).to have_button('Next', disabled: false)

      expect(content.content_file_binaries.sole)
        .to have_attributes(filepath: 'folder/dropzone_upload.txt', file_location: 'mount', mount_path:)
    end
  end

  context 'when discovering files on Globus' do
    let(:globus_path) { File.join(Settings.globus.directory, "uploads/#{user.sunetid}/objects/bc123df4567") }

    before do
      allow(GlobusClient).to receive(:mkdir) { FileUtils.mkdir_p(globus_path) }
      allow(GlobusClient).to receive(:writable?) { File.directory?(globus_path) }
    end

    after do
      FileUtils.rm_rf(Settings.globus.directory)
    end

    it 'creates the Globus link and discovers the files' do
      visit_files_step

      # Globus isn't called until the Globus radio is selected.
      expect(page).to have_field('Select files from mount')
      expect(page).to have_no_button('Create Globus link')
      expect(GlobusClient).not_to have_received(:writable?)

      choose 'Globus'
      click_button 'Create Globus link'

      expect(page).to have_link('Open Globus')
      expect(page).to have_no_css('a.disabled', text: 'Open Globus')
      expect(GlobusClient).to have_received(:mkdir)

      choose 'Select files from mount'
      expect(page).to have_no_link('Open Globus')

      choose 'Globus'
      expect(page).to have_link('Open Globus')

      FileUtils.cp(file_fixture('dropzone_upload.txt'), File.join(globus_path, 'dropzone_upload.txt'))
      within('turbo-frame', id: /globus/) { click_button 'Discover files' }

      expect(page).to have_css('[role="status"]', text: 'Discovering files...')

      content = mutable_content
      DiscoverFilesJob.perform_now(content:, mount_path: globus_path, file_location: :globus)

      expect(page).to have_css('tbody th', exact_text: 'dropzone_upload.txt')
      expect(content.content_file_binaries.sole)
        .to have_attributes(filepath: 'dropzone_upload.txt', file_location: 'globus', mount_path: globus_path)
    end
  end
end
