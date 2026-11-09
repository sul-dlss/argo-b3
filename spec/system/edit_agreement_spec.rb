# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Edit an agreement' do
  include_context 'with show page object client'

  let(:druid) { 'druid:bc123df4567' }
  let(:cocina_object) do
    build(:agreement_with_metadata, id: druid, title: 'My agreement', source_id: 'sul:agreement-1')
  end
  let(:opened_cocina_object) { cocina_object.new(version: 2, lock: 'opened-lock') }
  let!(:user) { create(:user) }

  # The version is closed, so editing opens a new version.
  let(:version_status) do
    Dor::Services::Client::ObjectVersion::VersionStatus.new(versionId: 1, open: false, openable: true,
                                                            closeable: false, assembling: false,
                                                            accessioning: false, discardable: false,
                                                            versionDescription: 'Initial version')
  end

  # Agreements are governed by the ur APO, so permission to edit it is permission to edit them.
  let(:solr_doc) { build(:solr_item, :agreement, druid:, apo_druid: Settings.ur_apo_druid) }

  before do
    create(:permission, :edit, workgroup: user.groups.first, target_druid: Settings.ur_apo_druid)

    sign_in(user)

    allow(Sdr::Repository).to receive_messages(find: cocina_object, find_solr: solr_doc, source_id_exists?: false,
                                               accession: nil)
    allow(Sdr::Repository).to receive(:update) { |cocina_object:, **| cocina_object.new(lock: 'updated-lock') }
    allow(version_client).to receive(:open).and_return(opened_cocina_object)
    allow(Sdr::WorkflowService).to receive(:workflows_for).and_return([])
  end

  it 'edits the agreement and deposits, after correcting a missing version description' do
    visit object_path(druid)
    click_link 'Edit agreement'

    expect(page).to have_current_path(edit_agreement_path(druid))
    expect(page).to have_css('h1', text: 'Edit agreement')
    expect(page).to have_css('#details-tab.active')
    expect(page).to have_no_css('#tags-tab')
    expect(page).to have_field('Title', with: 'My agreement')
    expect(page).to have_field('Source ID', with: 'sul:agreement-1')

    fill_in 'Title', with: 'My changed agreement'
    fill_in 'Source ID', with: 'sul:agreement-2'

    # The tab and the submit button are both labeled "Deposit".
    find_by_id('deposit-tab').click
    expect(page).to have_css('#deposit-tab.active')
    # The version is closed, so there is no version description to prefill.
    expect(page).to have_field('Version description', with: '')
    click_button 'Deposit', type: 'submit'

    expect(page).to have_invalid_feedback('Version description', "can't be blank")
    expect(page).to have_field('Title', with: 'My changed agreement', visible: :all)
    expect(Sdr::Repository).not_to have_received(:update)

    fill_in 'Version description', with: 'Changed the title'
    # Leaving the field clears its error, which moves the buttons up; leave it before clicking.
    find_field('Version description').send_keys(:tab)
    expect(page).to have_no_css('.invalid-feedback', text: "can't be blank")
    click_button 'Deposit', type: 'submit'

    expect(page).to have_current_path(object_path(druid))
    expect(page).to have_toast('Agreement updated and deposit started.')

    expect(version_client).to have_received(:open)
      .with(description: 'Changed the title', opening_user_name: user.sunetid)
    expect(Sdr::Repository).to have_received(:update)
      .with(cocina_object: having_attributes(
        version: 2, lock: 'opened-lock', type: Cocina::Models::ObjectType.agreement,
        identification: having_attributes(sourceId: 'sul:agreement-2'),
        description: having_attributes(title: [having_attributes(value: 'My changed agreement')]),
        access: having_attributes(view: 'dark', download: 'none')
      ),
            user_name: user.sunetid, description: nil)
    expect(Sdr::Repository).to have_received(:accession)
      .with(cocina_object: having_attributes(lock: 'updated-lock'), user_name: user.sunetid, context: {})
  end

  it 'saves the agreement as a draft and goes on to manage files' do
    visit edit_agreement_path(druid)

    fill_in 'Title', with: 'My changed agreement'
    find_by_id('deposit-tab').click
    fill_in 'Version description', with: 'Changed the title'
    click_button 'Save draft and edit files'

    expect(page).to have_current_path(edit_content_path(druid))
    expect(Sdr::Repository).to have_received(:update)
    expect(Sdr::Repository).not_to have_received(:accession)
  end
end
