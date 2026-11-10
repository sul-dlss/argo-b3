# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Edit a collection' do
  include_context 'with show page object client'

  let(:druid) { 'druid:bb123cd4567' }
  let(:apo_druid) { 'druid:dm456gh7890' }
  let(:other_apo_druid) { 'druid:xz987wv6543' }
  let(:cocina_object) do
    build(:collection_with_metadata, id: druid, title: 'My collection', admin_policy_id: apo_druid).new(
      access: { view: 'world', copyright: 'My copyright.', useAndReproductionStatement: 'My use statement.',
                license: 'https://creativecommons.org/publicdomain/zero/1.0/legalcode' }
    )
  end
  let(:opened_cocina_object) { cocina_object.new(version: 2, lock: 'opened-lock') }
  let(:apo_cocina_object) do
    build(:admin_policy_with_metadata, id: apo_druid).new(
      administrative: {
        hasAdminPolicy: 'druid:hv992ry2431',
        hasAgreement: 'druid:hp308wm0436',
        accessTemplate: { view: 'stanford', download: 'stanford',
                          copyright: 'Copyright © Stanford University.',
                          license: 'https://creativecommons.org/licenses/by/4.0/legalcode' }
      }
    )
  end
  let(:other_apo_cocina_object) do
    build(:admin_policy_with_metadata, id: other_apo_druid).new(
      administrative: {
        hasAdminPolicy: 'druid:hv992ry2431',
        hasAgreement: 'druid:hp308wm0436',
        accessTemplate: { view: 'dark', download: 'none', copyright: 'Other APO copyright.' }
      }
    )
  end
  let!(:user) { create(:user) }
  let(:solr_doc) do
    {
      Search::Fields::ID => druid,
      Search::Fields::OBJECT_TYPES => ['collection'],
      Search::Fields::TITLE => 'My collection',
      Search::Fields::APO_DRUID => [apo_druid],
      Search::Fields::APO_TITLE => ['My APO']
    }
  end

  # The version is closed, so depositing opens a new version.
  let(:version_status) do
    Dor::Services::Client::ObjectVersion::VersionStatus.new(versionId: 1, open: false, openable: true,
                                                            closeable: false, assembling: false,
                                                            accessioning: false, discardable: false,
                                                            versionDescription: 'Initial version')
  end

  before do
    create(:permission, :edit, workgroup: user.groups.first, target_druid: apo_druid)
    create(:permission, :edit, workgroup: user.groups.first, target_druid: other_apo_druid)

    sign_in(user)

    cocina_objects = { druid => cocina_object, apo_druid => apo_cocina_object,
                       other_apo_druid => other_apo_cocina_object }
    allow(Sdr::Repository).to receive(:find) { |druid:, **| cocina_objects.fetch(druid) }
    allow(Sdr::Repository).to receive_messages(find_solr: solr_doc, accession: nil)
    allow(Sdr::Repository).to receive(:update) { |cocina_object:, **| cocina_object.new(lock: 'updated-lock') }
    allow(version_client).to receive(:open).and_return(opened_cocina_object)
    allow(Searchers::AdminPolicyList).to receive(:call)
      .and_return([['My APO', apo_druid], ['Another APO', other_apo_druid]])
    allow(Sdr::WorkflowService).to receive(:workflows_for).and_return([])
    allow(Searchers::CollectionItemCount).to receive(:call).and_return(0)
  end

  it 'edits and deposits the collection, applying the APO defaults except for view access' do
    visit object_path(druid)
    click_link 'Edit collection'

    expect(page).to have_current_path(edit_collection_path(druid))
    expect(page).to have_css('h1', text: 'Edit and deposit collection')
    expect(page).to have_field('FOLIO Instance HRID')
    expect(page).to have_no_field('Barcode')

    click_button 'Next'
    expect(page).to have_css('#rights-tab.active')
    expect(page).to have_select('APO', selected: 'My APO')
    expect(page).to have_field('Copyright', with: 'My copyright.')

    select 'Another APO', from: 'APO'
    # Selecting an APO only shows its defaults.
    expect(page).to have_css('#collection_copyright_help', text: 'APO default = Other APO copyright.')
    expect(page).to have_field('Copyright', with: 'My copyright.')

    click_button 'Apply APO defaults'

    expect(page).to have_field('Copyright', with: 'Other APO copyright.')
    # The APO has no default use and reproduction or license, so the collection's are cleared.
    expect(page).to have_field('Use and reproduction', with: '')
    expect(page).to have_select('License', selected: '')
    # View access is not an APO default for a collection.
    expect(page).to have_select('View access', selected: 'world')

    click_button 'Next'
    expect(page).to have_css('#deposit-tab.active')
    expect(page).to have_no_button('Save as draft')
    fill_in 'Version description', with: 'Moved to another APO'
    click_button 'Deposit'

    expect(page).to have_current_path(object_path(druid))
    expect(page).to have_toast('Collection updated and deposit started.')

    expect(version_client).to have_received(:open)
      .with(description: 'Moved to another APO', opening_user_name: user.sunetid)
    expect(Sdr::Repository).to have_received(:update) do |args|
      updated_cocina_object = args[:cocina_object]
      expect(updated_cocina_object.lock).to eq('opened-lock')
      expect(updated_cocina_object.administrative.hasAdminPolicy).to eq(other_apo_druid)
      expect(updated_cocina_object.access.view).to eq('world')
      expect(updated_cocina_object.access.copyright).to eq('Other APO copyright.')
      expect(updated_cocina_object.access.license).to be_nil
    end
    expect(Sdr::Repository).to have_received(:accession)
      .with(cocina_object: having_attributes(lock: 'updated-lock'), user_name: user.sunetid, context: {})
  end

  it 'flags the description when Refresh on deposit is checked without a FOLIO Instance HRID' do
    visit edit_collection_path(druid)
    check 'Refresh on deposit'
    click_button 'Next'
    click_button 'Next'
    fill_in 'Version description', with: 'Refreshing from FOLIO'

    click_button 'Deposit'

    expect(page).to have_css('#description-tab.active.is-invalid')
    expect(page).to have_invalid_feedback('collection_catalog_record_id',
                                          'A FOLIO Instance HRID must be provided to allow Refresh on deposit.')
    expect(Sdr::Repository).not_to have_received(:update)
    expect(Sdr::Repository).not_to have_received(:accession)
  end
end
