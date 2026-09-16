# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Create an item' do
  let(:workgroup) { 'sdr:test-workgroup' }
  let!(:user) { create(:user, groups: [workgroup]) }

  let(:apo_druid) { generate(:unique_druid) }
  let(:apo_title) { 'My APO' }

  before do
    sign_in user

    create(:permission, :edit, workgroup:, target_druid: apo_druid)

    allow(Searchers::AdminPolicyList).to receive(:call).and_return([[apo_title, apo_druid]])
  end

  context 'when valid' do
    let(:registered_cocina_object) { build(:dro_with_metadata, admin_policy_id: apo_druid) }
    let(:druid) { registered_cocina_object.externalIdentifier }

    let(:object_client) do
      instance_double(Dor::Services::Client::Object, version: version_client, milestones: milestones_client,
                                                     user_version: user_version_client,
                                                     release_tags: release_tags_client)
    end
    let(:version_client) { instance_double(Dor::Services::Client::ObjectVersion, inventory: [], status: version_status) }
    let(:version_status) do
      instance_double(Dor::Services::Client::ObjectVersion::VersionStatus, accessioning?: false, closed?: false)
    end
    let(:user_version_client) { instance_double(Dor::Services::Client::UserVersion, inventory: []) }
    let(:milestones_client) { instance_double(Dor::Services::Client::Milestones, list: []) }
    let(:release_tags_client) { instance_double(Dor::Services::Client::ReleaseTags, list: []) }

    before do
      allow(Sdr::Repository).to receive_messages(accession: nil, create_release_tag: nil,
                                                 register: registered_cocina_object, find: registered_cocina_object,
                                                 find_solr: build(:solr_item, druid:, title: 'The Title', apo_druid:),
                                                 lock: registered_cocina_object.lock,
                                                 source_id_exists?: false)
      allow(Sdr::WorkflowService).to receive(:workflows_for).and_return([])
      allow(PurlPreviewService).to receive(:call).and_return('<html><body><main></main></body></html>')
      allow(Dor::Services::Client).to receive(:object).with(druid).and_return(object_client)
    end

    it 'registers a valid cocina object' do
      visit new_item_path

      expect(page).to have_link('Cancel', href: root_path)
      expect(page).to have_button('Next')
      expect(page).to have_no_button('Previous')

      fill_in 'Source ID', with: 'new:source-id'
      select 'image', from: 'Content type'

      click_button 'Next'
      expect(page).to have_css('#description-tab.active')

      # 'Enter title myself' is selected by default.
      fill_in 'Title', with: 'The Title'

      click_button 'Next'
      expect(page).to have_css('#rights-tab.active')
      select apo_title, from: 'APO'

      # Only the section for the selected access settings toggle option is shown. The other
      # section is disabled so that its fields are not submitted.
      expect(page).to have_no_css('legend', text: 'Access settings during embargo')
      expect(page).to have_select('item[access_view]', disabled: false)
      expect(page).to have_select('item[embargo_view]', disabled: true, visible: :all)

      choose 'With embargo', allow_label_click: true
      expect(page).to have_css('legend', text: 'Access settings during embargo')
      expect(page).to have_select('item[embargo_view]', disabled: false)
      expect(page).to have_select('item[access_view]', disabled: false)

      choose 'Without embargo', allow_label_click: true
      expect(page).to have_no_css('legend', text: 'Access settings during embargo')
      expect(page).to have_select('item[embargo_view]', disabled: true, visible: :all)

      # No license is selected by default.
      expect(page).to have_select('License', selected: '')

      fill_in 'Use and reproduction', with: 'Property rights reside with the repository.'
      fill_in 'Copyright', with: 'Copyright © Stanford University.'
      select 'CC Zero 1.0', from: 'License'

      click_button 'Next'
      expect(page).to have_css('#tags-tab.active')
      fill_in 'item[other_tags_attributes][0][tag]', with: 'Registered By : mjgiarlo'
      click_button 'Add another tag'
      fill_in 'item[other_tags_attributes][1][tag]', with: 'Remediated By : 5.0.0'
      fill_in 'item[project_tags_attributes][0][tag]', with: 'Argo'
      click_button 'Add another project'
      fill_in 'item[project_tags_attributes][1][tag]', with: 'Google Books'
      fill_in 'item[ticket_tags_attributes][0][tag]', with: 'ABC-123'
      click_button 'Add another ticket'
      fill_in 'item[ticket_tags_attributes][1][tag]', with: 'ABC-456'

      click_button 'Next'
      expect(page).to have_css('#release-tab.active')
      choose 'Release to:'
      check 'SearchWorks'

      click_button 'Next'
      expect(page).to have_css('#deposit-tab.active')
      expect(page).to have_button('Previous')
      expect(page).to have_no_button('Next')

      click_button('Register only')

      expect(page).to have_current_path("/objects/#{druid}")
      expect(page).to have_toast('Item registered.')

      expect(Sdr::Repository).to have_received(:register) do |args|
        request_cocina_object = args[:request_cocina_object]
        expect(request_cocina_object).to be_a(Cocina::Models::RequestDRO)
        expect(request_cocina_object.type).to eq(Cocina::Models::ObjectType.image)
        expect(request_cocina_object.identification.sourceId).to eq('new:source-id')
        expect(request_cocina_object.administrative.hasAdminPolicy).to eq(apo_druid)
        expect(request_cocina_object.description.title.first.value).to eq('The Title')
        expect(request_cocina_object.access.view).to eq('world')
        expect(request_cocina_object.access.download).to eq('world')
        expect(request_cocina_object.access.useAndReproductionStatement)
          .to eq('Property rights reside with the repository.')
        expect(request_cocina_object.access.copyright).to eq('Copyright © Stanford University.')
        expect(request_cocina_object.access.license)
          .to eq('https://creativecommons.org/publicdomain/zero/1.0/legalcode')

        expect(args[:user_name]).to eq(user.sunetid)
        expect(args[:tags]).to eq(['Registered By : mjgiarlo', 'Remediated By : 5.0.0',
                                   'Project : Argo', 'Project : Google Books',
                                   'Ticket : ABC-123', 'Ticket : ABC-456'])
      end

      expect(Sdr::Repository).not_to have_received(:accession)

      expect(Sdr::Repository).to have_received(:create_release_tag)
        .with(druid:, user_name: user.sunetid, release_target: 'Searchworks', release: true)
    end

    it 'registers a valid cocina object without a license or rights statements' do
      visit new_item_path

      fill_in 'Source ID', with: 'new:source-id'

      find_by_id('description-tab').click
      fill_in 'Title', with: 'The Title'

      find_by_id('rights-tab').click
      select apo_title, from: 'APO'
      # Leaving Use and reproduction, Copyright, and License blank.

      find_by_id('deposit-tab').click
      click_button('Register only')

      expect(page).to have_current_path("/objects/#{druid}")

      expect(Sdr::Repository).to have_received(:register) do |args|
        access = args[:request_cocina_object].access
        expect(access.useAndReproductionStatement).to be_nil
        expect(access.copyright).to be_nil
        expect(access.license).to be_nil
      end
    end

    it 'registers a valid cocina object with a generated source id' do
      allow(SecureRandom).to receive(:uuid).and_return('11111111-1111-1111-1111-111111111111')

      visit new_item_path

      choose 'Enter prefix to autogenerate source ID'
      fill_in 'Source ID prefix', with: 'new'

      find_by_id('description-tab').click
      fill_in 'Title', with: 'The Title'

      find_by_id('rights-tab').click
      select apo_title, from: 'APO'

      find_by_id('deposit-tab').click
      click_button('Register only')

      expect(page).to have_current_path("/objects/#{druid}")
      expect(page).to have_toast('Item registered.')

      expect(Sdr::Repository).to have_received(:register) do |args|
        request_cocina_object = args[:request_cocina_object]
        expect(request_cocina_object.identification.sourceId).to eq('new:11111111-1111-1111-1111-111111111111')
      end
    end

    it 'registers a valid cocina object with a Folio Instance HRID instead of a title' do
      visit new_item_path

      fill_in 'Source ID', with: 'new:source-id'

      find_by_id('description-tab').click
      choose 'Use FOLIO Instance HRID to retrieve title'
      fill_in 'Folio Instance HRID', with: 'in11403803'

      find_by_id('rights-tab').click
      select apo_title, from: 'APO'

      find_by_id('deposit-tab').click
      click_button('Register only')

      expect(page).to have_current_path("/objects/#{druid}")
      expect(page).to have_toast('Item registered.')

      expect(Sdr::Repository).to have_received(:register) do |args|
        catalog_link = args[:request_cocina_object].identification.catalogLinks.first
        expect(catalog_link.catalog).to eq('folio')
        expect(catalog_link.catalogRecordId).to eq('in11403803')
        expect(catalog_link.refresh).to be(true)
      end
    end

    it 'registers a valid cocina object with a description from a spreadsheet' do
      visit new_item_path

      fill_in 'Source ID', with: 'new:source-id'

      find_by_id('description-tab').click
      choose 'Upload description spreadsheet'
      attach_file 'Upload a CSV file', file_fixture('item_description.csv')

      find_by_id('rights-tab').click
      select apo_title, from: 'APO'

      find_by_id('deposit-tab').click
      click_button('Register only')

      expect(page).to have_current_path("/objects/#{druid}")
      expect(page).to have_toast('Item registered.')

      expect(Sdr::Repository).to have_received(:register) do |args|
        description = args[:request_cocina_object].description
        expect(description.title.first.value).to eq('A spreadsheet title')
        expect(description.note.first.value).to eq('A note')
      end
    end

    it 'registers a valid cocina object with Stanford access' do
      visit new_item_path

      fill_in 'Source ID', with: 'new:source-id'

      find_by_id('description-tab').click
      fill_in 'Title', with: 'The Title'

      find_by_id('rights-tab').click
      select apo_title, from: 'APO'
      select 'Stanford', from: 'View access'
      select 'Stanford', from: 'Download access'

      find_by_id('deposit-tab').click
      click_button('Register only')

      expect(page).to have_current_path("/objects/#{druid}")

      expect(Sdr::Repository).to have_received(:register) do |args|
        access = args[:request_cocina_object].access
        expect(access.view).to eq('stanford')
        expect(access.download).to eq('stanford')
        expect(access.location).to be_nil
      end
    end

    it 'registers a valid cocina object with location-based access' do
      visit new_item_path

      fill_in 'Source ID', with: 'new:source-id'

      find_by_id('description-tab').click
      fill_in 'Title', with: 'The Title'

      find_by_id('rights-tab').click
      select apo_title, from: 'APO'
      select 'Location Based', from: 'View access'
      select 'Special collections', from: 'Location'

      find_by_id('deposit-tab').click
      click_button('Register only')

      expect(page).to have_current_path("/objects/#{druid}")

      expect(Sdr::Repository).to have_received(:register) do |args|
        access = args[:request_cocina_object].access
        expect(access.view).to eq('location-based')
        expect(access.download).to eq('location-based')
        expect(access.location).to eq('spec')
      end
    end

    it 'registers a valid cocina object with an embargo' do
      visit new_item_path

      fill_in 'Source ID', with: 'new:source-id'

      find_by_id('description-tab').click
      fill_in 'Title', with: 'The Title'

      find_by_id('rights-tab').click
      select apo_title, from: 'APO'
      choose 'With embargo', allow_label_click: true

      fill_in 'When will this embargo end?', with: Date.new(2040, 6, 1)
      within_fieldset('Access settings during embargo') do
        select 'Dark', from: 'View access'
      end
      within_fieldset('Access settings once embargo ends') do
        select 'Stanford', from: 'View access'
      end

      find_by_id('deposit-tab').click
      click_button('Register only')

      expect(page).to have_current_path("/objects/#{druid}")

      expect(Sdr::Repository).to have_received(:register) do |args|
        access = args[:request_cocina_object].access
        expect(access.view).to eq('stanford')
        expect(access.download).to eq('stanford')
        expect(access.embargo.releaseDate).to eq(DateTime.parse('2040-06-01'))
        expect(access.embargo.view).to eq('dark')
        expect(access.embargo.download).to eq('none')
      end
    end

    it 'registers a valid cocina object without tags' do
      visit new_item_path

      fill_in 'Source ID', with: 'new:source-id'

      find_by_id('description-tab').click
      fill_in 'Title', with: 'The Title'

      find_by_id('rights-tab').click
      select apo_title, from: 'APO'

      find_by_id('tags-tab').click
      # Leaving the blank tag row empty.

      find_by_id('deposit-tab').click
      click_button('Register only')

      expect(page).to have_current_path("/objects/#{druid}")

      expect(Sdr::Repository).to have_received(:register) do |args|
        expect(args[:tags]).to eq([])
      end
    end

    it 'registers a valid cocina object after removing a tag' do
      visit new_item_path

      fill_in 'Source ID', with: 'new:source-id'

      find_by_id('description-tab').click
      fill_in 'Title', with: 'The Title'

      find_by_id('rights-tab').click
      select apo_title, from: 'APO'

      find_by_id('tags-tab').click
      fill_in 'item[other_tags_attributes][0][tag]', with: 'Registered By : mjgiarlo'
      click_button 'Add another tag'
      fill_in 'item[other_tags_attributes][1][tag]', with: 'Project : Argo'

      within 'fieldset', text: 'Tags' do
        within first('.form-instance') do
          click_button 'Remove'
        end
        expect(page).to have_css('.form-instance', count: 1)
      end

      find_by_id('deposit-tab').click
      click_button('Register only')

      expect(page).to have_current_path("/objects/#{druid}")

      expect(Sdr::Repository).to have_received(:register) do |args|
        expect(args[:tags]).to eq(['Project : Argo'])
      end
    end

    it 'registers a valid cocina object when project and ticket tags include prefixes' do
      visit new_item_path

      fill_in 'Source ID', with: 'new:source-id'

      find_by_id('description-tab').click
      fill_in 'Title', with: 'The Title'

      find_by_id('rights-tab').click
      select apo_title, from: 'APO'

      find_by_id('tags-tab').click
      fill_in 'item[project_tags_attributes][0][tag]', with: 'Project : Argo'
      fill_in 'item[ticket_tags_attributes][0][tag]', with: 'Ticket : ABC-123'

      find_by_id('deposit-tab').click
      click_button('Register only')

      expect(page).to have_current_path("/objects/#{druid}")

      expect(Sdr::Repository).to have_received(:register) do |args|
        expect(args[:tags]).to eq(['Project : Argo', 'Ticket : ABC-123'])
      end
    end

    it 'registers and redirects to add files' do
      visit new_item_path

      fill_in 'Source ID', with: 'new:source-id'
      select 'book', from: 'Content type'

      find_by_id('description-tab').click
      fill_in 'Title', with: 'The Title'

      find_by_id('rights-tab').click
      select apo_title, from: 'APO'

      find_by_id('deposit-tab').click
      click_button('Register and add files')

      expect(page).to have_current_path(edit_content_path(druid))
      expect(page).to have_toast('Item registered.')

      expect(Sdr::Repository).to have_received(:register) do |args|
        request_cocina_object = args[:request_cocina_object]
        expect(request_cocina_object.type).to eq(Cocina::Models::ObjectType.book)
      end
      expect(Sdr::Repository).not_to have_received(:accession)
    end

    it 'cancels item creation' do
      visit new_item_path

      click_link 'Cancel'
      expect(page).to have_current_path(root_path)
    end

    it 'cancels item creation returning to referring page' do
      visit root_path
      click_link_or_button 'Item'

      expect(page).to have_link('Cancel')
      click_link 'Cancel'
      expect(page).to have_current_path(root_path)
    end
  end

  context 'when invalid' do
    before do
      allow(Sdr::Repository).to receive(:register)
      allow(Sdr::Repository).to receive(:accession)
      allow(Sdr::Repository).to receive(:source_id_exists?).and_return(false)
    end

    it 'shows validation errors and does not register or accession' do
      visit new_item_path

      fill_in 'Source ID', with: 'new:source-id'
      # Leaving Title blank.

      find_by_id('release-tab').click
      choose 'Release to:'

      find_by_id('deposit-tab').click
      click_button('Register only')

      find_by_id('description-tab').click
      expect(page).to have_invalid_feedback('Title', "can't be blank")

      find_by_id('release-tab').click
      expect(page).to have_css('.invalid-feedback', text: 'At least one target must be selected')

      expect(Sdr::Repository).not_to have_received(:register)
      expect(Sdr::Repository).not_to have_received(:accession)
    end

    it 'requires a Folio Instance HRID instead of a title when retrieving the title from the catalog' do
      visit new_item_path

      fill_in 'Source ID', with: 'new:source-id'

      find_by_id('description-tab').click
      choose 'Use FOLIO Instance HRID to retrieve title'
      # Leaving Title and Folio Instance HRID blank.

      find_by_id('deposit-tab').click
      click_button('Register only')

      find_by_id('description-tab').click
      expect(page).to have_invalid_feedback('Folio Instance HRID', "can't be blank")

      expect(Sdr::Repository).not_to have_received(:register)
      expect(Sdr::Repository).not_to have_received(:accession)
    end

    it 'requires a description spreadsheet when uploading a description spreadsheet' do
      visit new_item_path

      fill_in 'Source ID', with: 'new:source-id'

      find_by_id('description-tab').click
      choose 'Upload description spreadsheet'
      # Leaving the spreadsheet unattached.

      find_by_id('deposit-tab').click
      click_button('Register only')

      find_by_id('description-tab').click
      expect(page).to have_invalid_feedback('Upload a CSV file', "can't be blank")

      expect(Sdr::Repository).not_to have_received(:register)
      expect(Sdr::Repository).not_to have_received(:accession)
    end

    it 'shows validation errors for a description spreadsheet without a title column' do
      visit new_item_path

      fill_in 'Source ID', with: 'new:source-id'

      find_by_id('description-tab').click
      choose 'Upload description spreadsheet'
      attach_file 'Upload a CSV file', file_fixture('item_description_invalid.csv')

      find_by_id('deposit-tab').click
      click_button('Register only')

      find_by_id('description-tab').click
      expect(page).to have_invalid_feedback('Upload a CSV file', 'Title column not found.')

      expect(Sdr::Repository).not_to have_received(:register)
      expect(Sdr::Repository).not_to have_received(:accession)
    end

    context 'when the source ID already exists' do
      before do
        allow(Sdr::Repository).to receive(:source_id_exists?).and_return(true)
      end

      it 'shows a validation error and does not register or accession' do
        visit new_item_path

        fill_in 'Source ID', with: 'new:source-id'

        find_by_id('description-tab').click
        fill_in 'Title', with: 'The Title'

        find_by_id('deposit-tab').click
        click_button('Register only')

        expect(page).to have_invalid_feedback('Source ID', 'already exists')

        expect(Sdr::Repository).not_to have_received(:register)
        expect(Sdr::Repository).not_to have_received(:accession)
      end
    end

    it 'shows validation errors for a malformed tag' do
      visit new_item_path

      fill_in 'Source ID', with: 'new:source-id'

      find_by_id('description-tab').click
      fill_in 'Title', with: 'The Title'

      find_by_id('tags-tab').click
      fill_in 'item[other_tags_attributes][0][tag]', with: 'Registered By'

      find_by_id('deposit-tab').click
      click_button('Register only')

      find_by_id('tags-tab').click
      expect(page).to have_css('.invalid-feedback',
                               text: 'must be a series of 2 or more strings delimited with space-padded colons')
      expect(page).to have_field('item[other_tags_attributes][0][tag]', with: 'Registered By')

      expect(Sdr::Repository).not_to have_received(:register)
      expect(Sdr::Repository).not_to have_received(:accession)
    end

    it 'requires an embargo release date when an embargo is selected' do
      visit new_item_path

      fill_in 'Source ID', with: 'new:source-id'

      find_by_id('description-tab').click
      fill_in 'Title', with: 'The Title'

      find_by_id('rights-tab').click
      choose 'With embargo', allow_label_click: true
      # Leaving the embargo release date blank.

      find_by_id('deposit-tab').click
      click_button('Register only')

      expect(page).to have_invalid_feedback('When will this embargo end?', "can't be blank")

      expect(Sdr::Repository).not_to have_received(:register)
      expect(Sdr::Repository).not_to have_received(:accession)
    end
  end
end
