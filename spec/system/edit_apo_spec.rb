# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Edit an APO' do
  include_context 'with show page object client'

  let(:druid) { 'druid:bc123df4567' }
  let(:agreement_druid) { 'druid:dd123fg4567' }
  let(:new_agreement_druid) { 'druid:ff234gh5678' }
  let(:cocina_object) do
    build(:admin_policy_with_metadata, id: druid, title: 'My APO', agreement_id: agreement_druid)
  end
  let(:opened_cocina_object) { cocina_object.new(version: 2, lock: 'opened-lock') }
  let!(:user) { create(:user) }
  let(:solr_doc) do
    {
      Search::Fields::ID => druid,
      Search::Fields::OBJECT_TYPES => ['APO'],
      Search::Fields::TITLE => 'My APO',
      Search::Fields::APO_DRUID => [Settings.ur_apo_druid],
      Search::Fields::AGREEMENT_DRUID => agreement_druid,
      Search::Fields::AGREEMENT_TITLE => 'My Agreement'
    }
  end

  # The version is closed, so editing opens a new version.
  let(:version_status) do
    Dor::Services::Client::ObjectVersion::VersionStatus.new(versionId: 1, open: false, openable: true,
                                                            closeable: false, assembling: false,
                                                            accessioning: false, discardable: false,
                                                            versionDescription: 'Initial version')
  end

  before do
    create(:permission, :edit, workgroup: user.groups.first, target_druid: druid)

    sign_in(user)

    allow(Sdr::Repository).to receive_messages(find: cocina_object, find_solr: solr_doc, accession: nil)
    allow(Sdr::Repository).to receive(:update) { |cocina_object:, **| cocina_object.new(lock: 'updated-lock') }
    allow(version_client).to receive(:open).and_return(opened_cocina_object)
    allow(Searchers::AgreementList).to receive(:call)
      .and_return([['My Agreement', agreement_druid], ['My other agreement', new_agreement_druid]])
    allow(Sdr::WorkflowService).to receive(:workflows_for).and_return([])
    allow(Searchers::AdminPolicyObjectCounts).to receive(:call)
      .and_return(Searchers::AdminPolicyObjectCounts::Result.new(item_count: 0, collection_count: 0))
  end

  it 'edits and deposits the APO' do
    visit object_path(druid)
    click_link 'Edit APO'

    expect(page).to have_current_path(edit_apo_path(druid))
    expect(page).to have_css('h1', text: 'Edit and deposit APO')
    expect(page).to have_field('Title', with: 'My APO')
    expect(page).to have_select('Agreement', selected: 'My Agreement')
    # The version is closed, so there is no version description to prefill.
    expect(page).to have_field('Version description', with: '')

    fill_in 'Title', with: 'My changed APO'
    select 'My other agreement', from: 'Agreement'
    select 'Stanford', from: 'View access'
    select 'Stanford', from: 'Download access'
    fill_in 'Default copyright', with: 'Copyright © Stanford University.'
    fill_in 'Version description', with: 'Changed the title'

    click_button 'Deposit'

    expect(page).to have_current_path(object_path(druid))
    expect(page).to have_toast('APO updated and deposit started.')

    expect(version_client).to have_received(:open)
      .with(description: 'Changed the title', opening_user_name: user.sunetid)
    expect(Sdr::Repository).to have_received(:update) do |args|
      updated_cocina_object = args[:cocina_object]
      expect(updated_cocina_object.version).to eq(2)
      expect(updated_cocina_object.lock).to eq('opened-lock')
      expect(updated_cocina_object.description.title.first.value).to eq('My changed APO')
      expect(updated_cocina_object.administrative.hasAgreement).to eq(new_agreement_druid)
      expect(updated_cocina_object.administrative.accessTemplate.view).to eq('stanford')
      expect(updated_cocina_object.administrative.accessTemplate.copyright).to eq('Copyright © Stanford University.')
      expect(args[:user_name]).to eq(user.sunetid)
    end
    expect(Sdr::Repository).to have_received(:accession)
      .with(cocina_object: having_attributes(lock: 'updated-lock'), user_name: user.sunetid, context: {})
  end

  it 'redisplays the form with errors when the version description is missing' do
    visit edit_apo_path(druid)

    fill_in 'Title', with: 'My changed APO'
    click_button 'Deposit'

    expect(page).to have_css('h1', text: 'Edit and deposit APO')
    expect(page).to have_invalid_feedback('Version description', "can't be blank")
    expect(page).to have_field('Title', with: 'My changed APO')
    expect(Sdr::Repository).not_to have_received(:update)
    expect(Sdr::Repository).not_to have_received(:accession)
  end
end
