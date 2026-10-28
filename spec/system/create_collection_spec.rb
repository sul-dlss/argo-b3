# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Create a collection' do
  include_context 'with show page object client'

  let(:workgroup) { 'sdr:test-workgroup' }
  let!(:user) { create(:user, groups: [workgroup]) }
  let(:apo_druid) { 'druid:hv992ry2431' }

  let(:registered_cocina_object) do
    build(:collection_with_metadata, id: 'druid:xz987wv6543', admin_policy_id: apo_druid)
  end
  let(:druid) { registered_cocina_object.externalIdentifier }
  let(:apo_cocina_object) do
    build(:admin_policy_with_metadata, id: apo_druid).new(
      administrative: {
        hasAdminPolicy: 'druid:hv992ry2431',
        hasAgreement: 'druid:hp308wm0436',
        accessTemplate: {
          useAndReproductionStatement: 'Use at will.',
          copyright: 'Copyright © Stanford University.',
          license: 'https://creativecommons.org/licenses/by/4.0/legalcode'
        }
      }
    )
  end

  before do
    sign_in user

    create(:permission, :edit, workgroup:, target_druid: apo_druid)

    allow(Searchers::AdminPolicyList).to receive(:call).and_return([['My APO', apo_druid]])
    cocina_objects = { apo_druid => apo_cocina_object, druid => registered_cocina_object }
    allow(Sdr::Repository).to receive(:find) { |druid:| cocina_objects.fetch(druid) }
    allow(Sdr::Repository).to receive_messages(register: registered_cocina_object,
                                               find_solr: build(:solr_item, druid:, title: 'My collection',
                                                                            object_type: 'collection',
                                                                            apo_druid:),
                                               lock: registered_cocina_object.lock)
    allow(Sdr::Repository).to receive(:create_release_tag)
    allow(Sdr::Repository).to receive(:accession)
    allow(Sdr::WorkflowService).to receive(:workflows_for).and_return([])
  end

  it 'registers and deposits a collection' do
    visit root_path
    click_on 'Collection'

    expect(page).to have_css('h1', text: 'Register and deposit collection')
    expect(page).to have_no_field('Upload description spreadsheet')
    fill_in 'Title', with: 'My collection'

    click_button 'Next'
    expect(page).to have_css('#rights-tab.active')
    select 'My APO', from: 'APO'
    select 'dark', from: 'View access'

    # The APO defaults are applied to the rights fields.
    expect(page).to have_field('Use and reproduction', with: 'Use at will.')
    expect(page).to have_field('Copyright', with: 'Copyright © Stanford University.')
    expect(page).to have_css('#collection_copyright_help', text: 'APO default = Copyright © Stanford University.')
    expect(page).to have_select('License', selected: 'CC Attribution 4.0 International')
    fill_in 'Copyright', with: 'My copyright.'

    click_button 'Next'
    expect(page).to have_css('#tags-tab.active')
    fill_in_tag 'collection[other_tags_attributes][0][tag]', with: 'Some : Tag'

    click_button 'Next'
    expect(page).to have_css('#release-tab.active')
    select 'Release collection and member items', from: 'SearchWorks'

    click_button 'Next'
    expect(page).to have_css('#deposit-tab.active')
    click_button 'Register and deposit collection'

    expect(page).to have_current_path("/objects/#{druid}")
    expect(page).to have_toast('Collection registered and deposit started.')

    expect(Sdr::Repository).to have_received(:register) do |args|
      request_cocina_object = args[:request_cocina_object]
      expect(request_cocina_object.type).to eq(Cocina::Models::ObjectType.collection)
      expect(request_cocina_object.administrative.hasAdminPolicy).to eq(apo_druid)
      expect(request_cocina_object.access.view).to eq('dark')
      expect(request_cocina_object.access.useAndReproductionStatement).to eq('Use at will.')
      expect(request_cocina_object.access.copyright).to eq('My copyright.')
      expect(request_cocina_object.access.license).to eq('https://creativecommons.org/licenses/by/4.0/legalcode')
      expect(request_cocina_object.description.title.first.value).to eq('My collection')
      expect(args[:tags]).to include('Some : Tag')
    end
    expect(Sdr::Repository).to have_received(:create_release_tag)
      .with(druid:, user_name: user.sunetid, release_target: 'Searchworks', release: true, release_what: 'collection')
    expect(Sdr::Repository).to have_received(:accession)
  end
end
