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
    let(:registered_cocina_object) { build(:dro_with_metadata) }
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
                                                 find_solr: build(:solr_item, druid:, title: 'The Title'),
                                                 lock: registered_cocina_object.lock,
                                                 source_id_exists?: false)
      allow(Sdr::WorkflowService).to receive(:workflows_for).and_return([])
      allow(PurlPreviewService).to receive(:call).and_return('<html><body><main></main></body></html>')
      allow(Dor::Services::Client).to receive(:object).with(druid).and_return(object_client)
    end

    it 'registers a valid cocina object' do
      visit new_item_path

      fill_in 'Source ID', with: 'new:source-id'
      fill_in 'Title', with: 'The Title'
      select 'image', from: 'Content type'

      find_by_id('rights-tab').click
      select apo_title, from: 'APO'

      find_by_id('release-tab').click
      choose 'Release to:'
      check 'SearchWorks'

      find_by_id('deposit-tab').click
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

        expect(args[:user_name]).to eq(user.sunetid)
      end

      expect(Sdr::Repository).not_to have_received(:accession)

      expect(Sdr::Repository).to have_received(:create_release_tag)
        .with(druid:, user_name: user.sunetid, release_target: 'Searchworks', release: true)
    end

    it 'registers a valid cocina object with a generated source id' do
      allow(SecureRandom).to receive(:uuid).and_return('11111111-1111-1111-1111-111111111111')

      visit new_item_path

      choose 'Enter prefix to autogenerate source ID'
      fill_in 'Source ID prefix', with: 'new'
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

    it 'registers and redirects to add files' do
      visit new_item_path

      fill_in 'Source ID', with: 'new:source-id'
      fill_in 'Title', with: 'The Title'
      select 'book', from: 'Content type'

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

      expect(page).to have_invalid_feedback('Title', "can't be blank")

      find_by_id('release-tab').click
      expect(page).to have_css('.invalid-feedback', text: 'At least one target must be selected')

      expect(Sdr::Repository).not_to have_received(:register)
      expect(Sdr::Repository).not_to have_received(:accession)
    end
  end
end
