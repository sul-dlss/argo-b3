# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Create an agreement' do
  include_context 'with show page object client'

  let(:workgroup) { 'sdr:test-workgroup' }
  let!(:user) { create(:user, groups: [workgroup]) }

  let(:registered_cocina_object) { build(:agreement_with_metadata, id: 'druid:xz987wv6543') }
  let(:druid) { registered_cocina_object.externalIdentifier }

  before do
    sign_in user

    create(:permission, :edit, workgroup:, target_druid: Settings.ur_apo_druid)

    allow(Sdr::Repository).to receive_messages(register: registered_cocina_object, find: registered_cocina_object,
                                               find_solr: build(:solr_item, druid:, title: 'My Agreement',
                                                                            object_type: 'agreement',
                                                                            apo_druid: Settings.ur_apo_druid),
                                               lock: registered_cocina_object.lock,
                                               source_id_exists?: false)
    allow(Sdr::WorkflowService).to receive(:workflows_for).and_return([])
  end

  it 'registers a dark agreement governed by the ur APO' do
    visit root_path
    click_on 'Agreement'

    expect(page).to have_css('h1', text: 'Register an agreement')
    fill_in 'Title', with: 'My Agreement'
    fill_in 'Source ID', with: 'sul:agreement-1'

    click_button 'Next'
    expect(page).to have_css('#tags-tab.active')
    fill_in_tag 'agreement[other_tags_attributes][0][tag]', with: 'Some : Tag'

    click_button 'Next'
    expect(page).to have_css('#deposit-tab.active')
    click_button 'Register only'

    expect(page).to have_current_path("/objects/#{druid}")
    expect(page).to have_toast('Agreement registered.')

    expect(Sdr::Repository).to have_received(:register) do |args|
      request_cocina_object = args[:request_cocina_object]
      expect(request_cocina_object.type).to eq(Cocina::Models::ObjectType.agreement)
      expect(request_cocina_object.identification.sourceId).to eq('sul:agreement-1')
      expect(request_cocina_object.administrative.hasAdminPolicy).to eq(Settings.ur_apo_druid)
      expect(request_cocina_object.access.to_h).to include(view: 'dark', download: 'none')
      expect(request_cocina_object.description.title.first.value).to eq('My Agreement')
      expect(args[:tags]).to include('Some : Tag')
    end
  end
end
