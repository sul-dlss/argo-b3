# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Edit an item' do
  include_context 'with show page object client'

  let(:druid) { 'druid:bc123df4567' }
  let(:cocina_object) { build(:dro_with_metadata, id: druid, source_id: 'sul:original') }
  let(:apo_druid) { cocina_object.administrative.hasAdminPolicy }
  let(:opened_cocina_object) { cocina_object.new(version: 2, lock: 'opened-lock') }
  let!(:user) { create(:user) }

  # The version is closed, so editing opens a new version.
  let(:version_status) do
    Dor::Services::Client::ObjectVersion::VersionStatus.new(versionId: 1, open: false, openable: true,
                                                            closeable: false, assembling: false,
                                                            accessioning: false, discardable: false,
                                                            versionDescription: 'Initial version')
  end

  before do
    create(:permission, :read_unrestricted, workgroup: user.groups.first)
    create(:permission, :edit, workgroup: user.groups.first, target_druid: druid)

    sign_in(user)

    allow(Sdr::Repository).to receive_messages(find: cocina_object, find_solr: build(:solr_item, druid:),
                                               source_id_exists?: false, accession: nil)
    allow(Sdr::Repository).to receive(:update) { |cocina_object:, **| cocina_object.new(lock: 'updated-lock') }
    allow(version_client).to receive(:open).and_return(opened_cocina_object)
    allow(Searchers::AdminPolicyList).to receive(:call).and_return([])
    allow(Searchers::CollectionListByDruid).to receive(:call).and_return([])
    allow(Sdr::WorkflowService).to receive(:workflows_for).and_return([])
    allow(PurlPreviewService).to receive(:call).and_return('<html><body><main></main></body></html>')
  end

  it 'edits the item and deposits' do
    visit object_path(druid)
    click_link 'Edit item'

    expect(page).to have_current_path(edit_item_path(druid))
    expect(page).to have_css('#details-tab.active')
    expect(page).to have_button('Save as draft')
    expect(page).to have_css('#deposit-tab', text: 'Deposit')
    expect(page).to have_no_button('Deposit', type: 'submit')

    fill_in 'Source ID', with: 'sul:changed'

    click_button 'APO, collection, rights'
    expect(page).to have_css('#rights-tab.active')
    # The user cannot otherwise select the item's APO, so it is labeled with its druid.
    expect(page).to have_select('APO', selected: DruidSupport.bare_druid_from(apo_druid))
    expect(page).to have_field('Without embargo', type: 'radio', checked: true, visible: :all)
    expect(page).to have_select('item[embargo_view]', disabled: true, visible: :all)
    fill_in 'Copyright', with: 'Copyright © Stanford University.'
    select 'CC Zero 1.0', from: 'License'

    # The tab and the submit button are both labeled "Deposit".
    find_by_id('deposit-tab').click
    expect(page).to have_css('#deposit-tab.active')
    # The version is closed, so there is no version description to prefill.
    expect(page).to have_field('Version description', with: '')
    fill_in 'Version description', with: 'Changed the source ID'

    click_button 'Deposit', type: 'submit'

    expect(page).to have_current_path(object_path(druid))
    expect(page).to have_toast('Item updated and deposit started.')

    expect(version_client).to have_received(:open)
      .with(description: 'Changed the source ID', opening_user_name: user.sunetid)
    expect(Sdr::Repository).to have_received(:update)
      .with(cocina_object: having_attributes(
        version: 2, lock: 'opened-lock',
        identification: having_attributes(sourceId: 'sul:changed'),
        administrative: having_attributes(hasAdminPolicy: apo_druid),
        access: having_attributes(copyright: 'Copyright © Stanford University.',
                                  license: 'https://creativecommons.org/publicdomain/zero/1.0/legalcode')
      ),
            user_name: user.sunetid, description: nil)
    expect(Sdr::Repository).to have_received(:accession)
      .with(cocina_object: having_attributes(lock: 'updated-lock'), user_name: user.sunetid)
  end
end
