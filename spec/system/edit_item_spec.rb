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
      .with(cocina_object: having_attributes(lock: 'updated-lock'), user_name: user.sunetid, context: {})
  end

  it 'edits the item and redirects to edit files' do
    visit edit_item_path(druid)

    fill_in 'Source ID', with: 'sul:changed'

    find_by_id('deposit-tab').click
    fill_in 'Version description', with: 'Changed the source ID'
    click_button 'Save draft and edit files'

    expect(page).to have_current_path(edit_content_path(druid))
    expect(page).to have_toast('Item updated.')

    expect(Sdr::Repository).to have_received(:update)
      .with(cocina_object: having_attributes(identification: having_attributes(sourceId: 'sul:changed')),
            user_name: user.sunetid, description: nil)
    expect(Sdr::Repository).not_to have_received(:accession)
  end

  context 'when the item has Folio catalog links' do
    let(:cocina_object) do
      build(:dro_with_metadata, id: druid, source_id: 'sul:original').then do |dro|
        dro.new(identification: dro.identification.to_h.merge(
          catalogLinks: [{ catalog: 'folio', catalogRecordId: 'in111', refresh: true },
                         { catalog: 'folio', catalogRecordId: 'in222', refresh: false }]
        ))
      end
    end

    before do
      allow(CatalogRepository).to receive_messages(exists?: true, title: 'Pride and prejudice')
    end

    it 'previews the FOLIO record for an additional FOLIO Instance HRID' do
      visit edit_item_path(druid)

      click_button 'Description'
      within('fieldset', text: 'Additional FOLIO Instance HRIDs') do
        click_button 'Preview FOLIO record'

        expect(page).to have_text('FOLIO title statement: Pride and prejudice')
      end
      expect(CatalogRepository).to have_received(:title).with(catalog_record_id: 'in222')
    end

    it 'disables uploading a description spreadsheet while refreshing on deposit' do
      visit edit_item_path(druid)

      click_button 'Description'
      expect(page).to have_field('Refresh on deposit', checked: true)
      expect(page).to have_field('Upload a CSV file', type: 'file', disabled: true)

      uncheck 'Refresh on deposit'
      expect(page).to have_field('Upload a CSV file', type: 'file', disabled: false)

      check 'Refresh on deposit'
      expect(page).to have_field('Upload a CSV file', type: 'file', disabled: true)
    end

    it 'replaces the additional FOLIO Instance HRIDs' do
      visit edit_item_path(druid)

      click_button 'Description'
      expect(page).to have_field('FOLIO Instance HRID', with: 'in111')
      within('fieldset', text: 'Additional FOLIO Instance HRIDs') do
        expect(page).to have_field('Additional FOLIO Instance HRID', with: 'in222')
        click_button 'Remove'
        # Removing the last row leaves a blank row.
        fill_in 'Additional FOLIO Instance HRID', with: 'in333'
        click_button 'Add another FOLIO Instance HRID'
        all('input[type="text"]').last.fill_in(with: 'in444')
      end

      find_by_id('deposit-tab').click
      fill_in 'Version description', with: 'Changed the HRIDs'
      click_button 'Save as draft', match: :first

      expect(page).to have_toast('Item updated.')
      expect(CatalogRepository).to have_received(:exists?).twice
      expect(Sdr::Repository).to have_received(:update) do |cocina_object:, **|
        expect(cocina_object.identification.catalogLinks.map(&:to_h)).to contain_exactly(
          { catalog: 'folio', catalogRecordId: 'in111', refresh: true },
          { catalog: 'folio', catalogRecordId: 'in333', refresh: false },
          { catalog: 'folio', catalogRecordId: 'in444', refresh: false },
          { catalog: 'previous folio', catalogRecordId: 'in222', refresh: false }
        )
      end
    end
  end

  context 'when discarding the draft' do
    let(:cocina_object) { build(:dro_with_metadata, id: druid, version: 2) }
    let(:version_status) do
      Dor::Services::Client::ObjectVersion::VersionStatus.new(versionId: 2, open: true, openable: false,
                                                              closeable: true, assembling: false,
                                                              accessioning: false, discardable: true,
                                                              versionDescription: 'Changed the title')
    end
    let!(:content) { create(:content, :mutable, druid:, lock: cocina_object.lock) }

    before do
      allow(version_client).to receive(:discard)
    end

    it 'confirms, discards the version and the mutable content, and returns to the object page' do
      visit edit_item_path(druid)

      accept_confirm(/\ADiscard this draft\?/) do
        click_link 'Discard draft'
      end

      expect(page).to have_current_path(object_path(druid))
      expect(page).to have_toast('Draft discarded.')
      expect(version_client).to have_received(:discard)
      expect(Content.exists?(content.id)).to be false
    end
  end
end
