# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Create an APO' do
  let(:user) { create(:user, :admin) }

  let(:agreement_druid) { 'druid:bc123df4567' }
  let(:agreement_title) { 'My Agreement' }

  let(:registered_cocina_object) do
    build(:admin_policy_with_metadata, id: druid, admin_policy_id: Settings.ur_apo_druid)
  end
  let(:druid) { 'druid:xz987wv6543' }

  let(:object_client) do
    instance_double(Dor::Services::Client::Object, version: version_client, milestones: milestones_client,
                                                   events: events_client,
                                                   user_version: user_version_client, lock: 'lock1')
  end
  let(:version_client) { instance_double(Dor::Services::Client::ObjectVersion, inventory: [], status: version_status) }
  let(:version_status) do
    instance_double(Dor::Services::Client::ObjectVersion::VersionStatus, accessioning?: true, closed?: true)
  end
  let(:user_version_client) { instance_double(Dor::Services::Client::UserVersion, inventory: []) }
  let(:milestones_client) { instance_double(Dor::Services::Client::Milestones, list: []) }
  let(:events_client) { instance_double(Dor::Services::Client::Events, list: []) }
  let(:event_types_client) { instance_double(Dor::Services::Client::EventTypes, list: %w[version_open]) }
  let(:solr_doc) do
    {
      Search::Fields::ID => druid,
      Search::Fields::OBJECT_TYPES => ['APO'],
      Search::Fields::TITLE => 'My APO',
      Search::Fields::APO_DRUID => [Settings.ur_apo_druid],
      Search::Fields::AGREEMENT_DRUID => agreement_druid,
      Search::Fields::AGREEMENT_TITLE => agreement_title
    }
  end

  before do
    allow(Searchers::AgreementList).to receive(:call).and_return([[agreement_title, agreement_druid]])
    allow(Sdr::Repository).to receive_messages(register: registered_cocina_object, accession: nil,
                                               find: registered_cocina_object, find_solr: solr_doc)
    allow(Sdr::WorkflowService).to receive(:workflows_for).and_return([])
    allow(Searchers::AdminPolicyObjectCounts).to receive(:call)
      .and_return(Searchers::AdminPolicyObjectCounts::Result.new(item_count: 0, collection_count: 0))
    allow(Dor::Services::Client).to receive(:object).with(druid).and_return(object_client)
    allow(Dor::Services::Client).to receive(:event_types).and_return(event_types_client)

    sign_in(user)
  end

  it 'registers and deposits the APO' do
    visit new_apo_path

    expect(page).to have_css('h1', text: 'Register and deposit APO')
    expect(page).to have_link('Cancel', href: root_path)

    fill_in 'Title', with: 'My APO'
    select agreement_title, from: 'Agreement'

    select 'World', from: 'View access'
    select 'World', from: 'Download access'
    fill_in 'Default use and reproduction', with: 'Property rights reside with the repository.'
    fill_in 'Default copyright', with: 'Copyright © Stanford University.'
    select 'CC Zero 1.0', from: 'Default license'

    click_button 'Register and deposit APO'

    expect(page).to have_current_path("/objects/#{druid}")
    expect(page).to have_toast('APO registered and deposit started')

    expect(Sdr::Repository).to have_received(:register) do |args|
      request_cocina_object = args[:request_cocina_object]
      expect(request_cocina_object).to be_a(Cocina::Models::RequestAdminPolicy)
      expect(request_cocina_object.description.title.first.value).to eq('My APO')
      expect(request_cocina_object.administrative.hasAdminPolicy).to eq(Settings.ur_apo_druid)
      expect(request_cocina_object.administrative.hasAgreement).to eq(agreement_druid)

      access_template = request_cocina_object.administrative.accessTemplate
      expect(access_template.view).to eq('world')
      expect(access_template.download).to eq('world')
      expect(access_template.useAndReproductionStatement).to eq('Property rights reside with the repository.')
      expect(access_template.copyright).to eq('Copyright © Stanford University.')
      expect(access_template.license).to eq('https://creativecommons.org/publicdomain/zero/1.0/legalcode')

      expect(args[:user_name]).to eq(user.sunetid)
    end
    expect(Sdr::Repository).to have_received(:accession)
      .with(cocina_object: registered_cocina_object, user_name: user.sunetid)
  end

  it 'redisplays the form with errors when the title is missing' do
    visit new_apo_path

    select agreement_title, from: 'Agreement'
    click_button 'Register and deposit APO'

    expect(page).to have_css('h1', text: 'Register and deposit APO')
    expect(page).to have_invalid_feedback('Title', "can't be blank")
    expect(page).to have_select('Agreement', selected: agreement_title)
    expect(Sdr::Repository).not_to have_received(:register)
  end
end
