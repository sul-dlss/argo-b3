# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Manage files' do
  let(:druid) { 'druid:bc123df4567' }
  let(:title) { 'My title' }

  let(:cocina_object) { build(:dro_with_metadata, id: druid) }
  let!(:user) { create(:user) }

  let(:object_client) do
    instance_double(Dor::Services::Client::Object, version: version_client, milestones: milestones_client,
                                                   user_version: user_version_client, lock: 'abc123',
                                                   release_tags: release_tags_client)
  end
  let(:version_client) { instance_double(Dor::Services::Client::ObjectVersion, inventory: [], status: version_status) }
  let(:version_status) do
    instance_double(Dor::Services::Client::ObjectVersion::VersionStatus, accessioning?: false, closed?: false)
  end
  let(:user_version_client) { instance_double(Dor::Services::Client::UserVersion, inventory: []) }
  let(:milestones_client) { instance_double(Dor::Services::Client::Milestones, list: [], date: false) }
  let(:release_tags_client) { instance_double(Dor::Services::Client::ReleaseTags, list: []) }

  before do
    create(:permission, :read_unrestricted, workgroup: user.groups.first)

    sign_in(user)

    allow(Sdr::Repository).to receive_messages(find: cocina_object,
                                               find_solr: build(:solr_item, druid:, title:))
    allow(Sdr::Repository).to receive(:update) { |cocina_object:, **| cocina_object.new(lock: 'updated-lock') }
    allow(StageFilesJob).to receive(:perform_later)
    allow(Sdr::WorkflowService).to receive(:workflows_for).and_return([])
    allow(PurlPreviewService).to receive(:call).and_return('<html><body><main></main></body></html>')
    allow(Dor::Services::Client).to receive(:object).with(druid).and_return(object_client)
  end

  def upload_file(filename)
    click_on 'Add files'
    attach_file(nil, Rails.root.join("spec/fixtures/files/#{filename}"), make_visible: true)
    expect(page).to have_css('li', text: filename)
  end

  it 'displays the object title and all tabs' do
    visit "/contents/#{druid}/edit"

    expect(page).to have_css('p', text: title)

    expect(page).to have_css('.nav-link', text: 'Add files')
    expect(page).to have_css('.nav-link', text: 'Structure')
    expect(page).to have_css('.nav-link', text: 'Deposit')
  end

  it 'updates the item details and deposits' do
    visit "/contents/#{druid}/edit"

    click_on 'Item details'

    expect(page).to have_select('Viewing direction', disabled: true)
    # The default content type cannot be OCRed.
    expect(page).to have_field('Yes', type: 'radio', disabled: true)
    expect(find_multi_select('Search for a language')[:class]).to include('disabled')

    select 'book', from: 'Content type'
    select 'right-to-left', from: 'Viewing direction'

    expect(page).to have_field('Yes', type: 'radio', disabled: false)
    # The languages remain disabled until OCR is requested.
    expect(find_multi_select('Search for a language')[:class]).to include('disabled')

    choose 'Yes'

    expect(find_multi_select('Search for a language')[:class]).not_to include('disabled')
    select_multi_option('English', from: 'Search for a language')

    click_on 'Deposit'
    click_button('Deposit')

    expect(page).to have_current_path("/objects/#{druid}")

    expect(Sdr::Repository).to have_received(:update)
      .with(cocina_object: having_attributes(type: Cocina::Models::ObjectType.book,
                                             structural: having_attributes(
                                               hasMemberOrders: [having_attributes(viewingDirection: 'right-to-left')]
                                             )),
            user_name: user.sunetid, description: nil)
    expect(StageFilesJob).to have_received(:perform_later)
      .with(content: Content.find_by!(druid:, immutable: false), accession: true, user:,
            workflow_context: { runOcr: true, ocrLanguages: ['English'] })
  end

  it 'warns about embedded text when running OCR on a document' do
    warning = 'Do not run OCR for files that already have embedded text.'

    visit "/contents/#{druid}/edit"

    click_on 'Item details'

    select 'document', from: 'Content type'

    expect(page).to have_no_text(warning)

    choose 'Yes'

    expect(page).to have_text(warning)

    # The warning is specific to documents.
    select 'book', from: 'Content type'

    expect(page).to have_no_text(warning)
  end

  it 'disables the OCR options again when the content type can no longer be OCRed' do
    visit "/contents/#{druid}/edit"

    click_on 'Item details'

    select 'book', from: 'Content type'
    choose 'Yes'
    select_multi_option('English', from: 'Search for a language')

    select 'map', from: 'Content type'

    expect(page).to have_field('Yes', type: 'radio', disabled: true)
    expect(find_multi_select('Search for a language')[:class]).to include('disabled')
  end

  context 'when no files have been uploaded yet' do
    it 'reports that there are no files' do
      visit "/contents/#{druid}/edit"

      within("turbo-frame[id^='show_content_']") do
        expect(page).to have_css('p', text: 'No files yet')
        expect(page).to have_no_css('li')
      end

      click_on 'Structure'

      expect(page).to have_css('p', text: 'No files yet.')
      expect(page).to have_no_button('Structure files')
      expect(page).to have_no_button('Append files to structure')
    end
  end

  context 'when a file has been uploaded' do
    it 'builds the structure from the file and deposits' do
      visit "/contents/#{druid}/edit"

      upload_file('dropzone_upload.txt')

      content = Content.find_by!(druid:)
      content_file_binary = content.content_file_binaries.sole
      expect(content_file_binary).to have_attributes(filepath: 'dropzone_upload.txt', file_location: 'attached')
      expect(content_file_binary.file).to be_attached
      expect(content.content_file_sets).to be_empty

      click_on 'Structure'

      expect(page).to have_css('p', text: 'There is 1 file that has not been added to the structure.')
      expect(page).to have_css('p', text: 'Strategy for structuring: Default (resource per file)')
      expect(page).to have_no_text('Reasons for not using')

      click_button('Structure files')

      expect(page).to have_toast('Structure built from files')
      expect(page).to have_css('h3', text: 'Structural metadata')

      content_file_set = content.content_file_sets.sole
      expect(content_file_set).to have_attributes(file_set_type: 'object')
      expect(content_file_set.content_files.sole.content_file_binary).to eq(content_file_binary)

      click_on 'Deposit'
      click_button('Deposit')

      expect(page).to have_current_path("/objects/#{druid}")

      expect(StageFilesJob).to have_received(:perform_later).with(content:, accession: true, user:,
                                                                  workflow_context: {})
    end
  end

  context 'when a file has been uploaded but not added to the structure' do
    it 'disables the deposit buttons until the files have been added to the structure' do
      visit "/contents/#{druid}/edit"

      upload_file('dropzone_upload.txt')

      click_on 'Deposit'

      expect(page).to have_button('Deposit', disabled: true)
      expect(page).to have_button('Save as draft', disabled: true)

      click_on 'Structure'
      click_button('Structure files')

      expect(page).to have_toast('Structure built from files')

      click_on 'Deposit'

      expect(page).to have_button('Deposit', disabled: false)
      expect(page).to have_button('Save as draft', disabled: false)
    end
  end

  context 'when the object is a book with images' do
    let(:cocina_object) do
      build(:dro_with_metadata, id: druid, type: Cocina::Models::ObjectType.book)
        .new(access: { view: 'world', download: 'world' })
    end

    it 'structures the book with a file set per page' do
      visit "/contents/#{druid}/edit"

      upload_file('page_0001.png')

      click_on 'Structure'

      expect(page).to have_css('p', text: 'Strategy for structuring: Book (resource per page)')
      expect(page).to have_no_text('Reasons for not using')

      click_button('Structure files')

      expect(page).to have_toast('Structure built from files')

      content = Content.find_by!(druid:)
      expect(content.content_file_sets.sole).to have_attributes(file_set_type: 'page', label: 'Page 1')
    end
  end

  context 'when the content type is changed to book' do
    let(:cocina_object) do
      build(:dro_with_metadata, id: druid).new(access: { view: 'world', download: 'world' })
    end

    it 'structures the files with the populator for the selected content type' do
      visit "/contents/#{druid}/edit"

      upload_file('page_0001.png')

      click_on 'Structure'

      expect(page).to have_css('p', text: 'Strategy for structuring: Default (resource per file)')

      click_on 'Item details'
      select 'book', from: 'Content type'

      click_on 'Structure'

      expect(page).to have_css('p', text: 'Strategy for structuring: Book (resource per page)')

      click_button('Structure files')

      expect(page).to have_toast('Structure built from files')
      expect(page).to have_css('p', text: 'Strategy for structuring: Book (resource per page)')

      content = Content.find_by!(druid:)
      expect(content.content_file_sets.sole).to have_attributes(file_set_type: 'page', label: 'Page 1')
    end
  end

  context 'when the object is a book that cannot be structured as a book' do
    let(:cocina_object) { build(:dro_with_metadata, id: druid, type: Cocina::Models::ObjectType.book) }

    it 'falls back to the default strategy and explains why' do
      visit "/contents/#{druid}/edit"

      upload_file('dropzone_upload.txt')

      click_on 'Structure'

      expect(page).to have_css('p', text: 'Strategy for structuring: Default (resource per file)')
      expect(page).to have_text('Reasons for not using Book (resource per page)')
      expect(page).to have_css('li', text: 'the object is dark')
      expect(page).to have_css('li', text: 'there are no image files')
    end
  end

  context 'when the structure has been built and another file is uploaded' do
    let(:content) { Content.find_by!(druid:) }

    # Builds the structure from one file, then uploads a second file that is not yet in the structure.
    def build_structure_then_upload_another_file
      visit "/contents/#{druid}/edit"

      upload_file('dropzone_upload.txt')

      click_on 'Structure'
      click_button('Structure files')

      expect(page).to have_toast('Structure built from files')

      upload_file('dropzone_upload2.txt')

      click_on 'Structure'

      expect(page).to have_css('p', text: 'There is 1 file that has not been added to the structure.')
    end

    it 'appends the file to the structure' do
      build_structure_then_upload_another_file

      original_content_file = content.content_files.sole

      click_button('Append files to structure')

      expect(page).to have_toast('Files appended to structure')

      expect(content.content_file_sets.pluck(:position)).to eq([1, 2])
      expect(content.content_file_sets.first.content_files.sole).to eq(original_content_file)
      expect(content.content_file_sets.last.content_files.sole.filepath).to eq('dropzone_upload2.txt')
    end

    it 'rebuilds the structure' do
      build_structure_then_upload_another_file

      original_content_file_set = content.content_file_sets.sole
      original_content_file = content.content_files.sole

      click_button('Clear and structure files again')

      expect(page).to have_toast('Structure built from files')

      expect(content.content_file_sets.pluck(:position)).to eq([1, 2])
      expect(ContentFileSet.exists?(original_content_file_set.id)).to be false
      expect(ContentFile.exists?(original_content_file.id)).to be false
      expect(content.content_files.map(&:filepath)).to eq(['dropzone_upload.txt', 'dropzone_upload2.txt'])
    end
  end

  context 'when editing a resource' do
    let(:content) { Content.find_by!(druid:) }

    def build_structure_then_edit_resource
      visit "/contents/#{druid}/edit"

      upload_file('dropzone_upload.txt')

      click_on 'Structure'
      click_button('Structure files')

      expect(page).to have_toast('Structure built from files')

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
      visit "/contents/#{druid}/edit"

      upload_file('dropzone_upload.txt')

      click_on 'Structure'
      click_button('Structure files')

      expect(page).to have_toast('Structure built from files')

      accept_confirm('Delete resource 1 and its files?') do
        click_button 'Delete resource 1'
      end

      expect(page).to have_toast('Resource deleted')
      # The structure is reloaded and the deleted file's binary is gone.
      expect(page).to have_css('p', text: 'No files yet.')
      expect(content.content_file_sets).to be_empty
      expect(content.content_file_binaries).to be_empty
    end

    it 'deletes the resource when every file is removed' do
      build_structure_then_edit_resource

      content_file_binary = content.content_file_binaries.sole

      expect(page).to have_no_text('Saving will delete this resource.')
      click_button 'Remove dropzone_upload.txt'
      expect(page).to have_no_field('Role')
      expect(page).to have_text('Saving will delete this resource.')

      click_button 'Save'

      expect(page).to have_toast('Resource deleted')
      # The structure is reloaded and the deleted file's binary is gone.
      expect(page).to have_css('p', text: 'No files yet.')
      expect(content.content_file_sets).to be_empty
      expect(ContentFileBinary.exists?(content_file_binary.id)).to be false
    end
  end

  context 'when deleting a file' do
    let(:content) { Content.find_by!(druid:) }

    it 'deletes a file that has not been added to the structure without confirming' do
      visit "/contents/#{druid}/edit"

      upload_file('dropzone_upload.txt')

      click_button 'Delete dropzone_upload.txt'

      expect(page).to have_toast('File deleted')
      within("turbo-frame[id^='show_content_']") do
        expect(page).to have_css('p', text: 'No files yet')
      end
      expect(content.content_file_binaries).to be_empty
    end

    it 'confirms and deletes the resource that deleting the file empties' do
      visit "/contents/#{druid}/edit"

      upload_file('dropzone_upload.txt')

      click_on 'Structure'
      click_button('Structure files')

      expect(page).to have_toast('Structure built from files')

      click_on 'Add files'
      accept_confirm('Deleting dropzone_upload.txt will also delete resource 1. Continue?') do
        click_button 'Delete dropzone_upload.txt'
      end

      expect(page).to have_toast('File deleted')
      within("turbo-frame[id^='show_content_']") do
        expect(page).to have_css('p', text: 'No files yet')
      end

      # The structure is reloaded and no longer includes the resource.
      click_on 'Structure'
      expect(page).to have_css('p', text: 'No files yet.')
      expect(content.content_file_sets).to be_empty
      expect(content.content_file_binaries).to be_empty
    end
  end

  context 'when discovering files on a mount' do
    let(:mount_path) { Dir.mktmpdir(nil, Rails.root.join('tmp')) }

    before do
      FileUtils.mkdir_p(File.join(mount_path, 'folder'))
      FileUtils.cp(file_fixture('dropzone_upload.txt'), File.join(mount_path, 'folder/dropzone_upload.txt'))
      allow(Settings.reload_intervals).to receive(:mount_discovery).and_return(100)
    end

    after do
      FileUtils.rm_rf(mount_path)
    end

    it 'discovers the files' do
      visit "/contents/#{druid}/edit"

      choose 'Use files from mount'
      fill_in 'Mount path', with: mount_path
      click_button 'Discover files'

      expect(page).to have_text('Discovering files...')

      content = Content.find_by!(druid:)
      expect(content.mount_state).to eq('discovering')

      DiscoverFilesJob.perform_now(content:, mount_path:)

      expect(page).to have_toast('Completed discovering files')
      expect(page).to have_field('Mount path')
      expect(page).to have_css('li', text: 'folder/dropzone_upload.txt')

      click_on 'Structure'

      expect(page).to have_css('p', text: 'There is 1 file that has not been added to the structure.')

      expect(content.content_file_binaries.sole)
        .to have_attributes(filepath: 'folder/dropzone_upload.txt', file_location: 'mount', mount_path:)
    end

    it 'disables deleting files until discovery completes' do
      visit "/contents/#{druid}/edit"

      upload_file('page_0001.png')

      expect(page).to have_button('Delete page_0001.png', disabled: false)

      choose 'Use files from mount'
      fill_in 'Mount path', with: mount_path
      click_button 'Discover files'

      expect(page).to have_text('Discovering files...')
      expect(page).to have_button('Delete page_0001.png', class: 'disabled')

      DiscoverFilesJob.perform_now(content: Content.find_by!(druid:), mount_path:)

      expect(page).to have_toast('Completed discovering files')
      expect(page).to have_css('li', text: 'folder/dropzone_upload.txt')
      expect(page).to have_no_button(class: 'disabled')
    end
  end
end
