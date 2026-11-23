# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Show object Apply APO defaults button' do
  include_context 'with show page object client'

  let(:druid) { 'druid:bc123df4567' }
  let(:object_type) { 'item' }
  let(:cocina_object) { build(:dro_with_metadata, id: druid, version: 2) }
  let(:user) { create(:user, :reader) }
  let(:solr_doc) do
    { Search::Fields::ID => druid, Search::Fields::TITLE => 'My object', Search::Fields::OBJECT_TYPES => [object_type] }
  end
  let(:rendered_page) { Capybara.string(response.body) }
  let(:button_selector) { "form[action='/objects/#{druid}/apo_defaults/new'] button" }
  # A closed version: Deposited.
  let(:version_status) do
    instance_double(Dor::Services::Client::ObjectVersion::VersionStatus, assembling?: false, accessioning?: false,
                                                                         closed?: true, openable?: true,
                                                                         closeable?: false, open?: false,
                                                                         discardable?: false, version: 2,
                                                                         version_description: 'Initial version')
  end

  before do
    allow(Sdr::Repository).to receive_messages(
      lock: object_lock,
      find: cocina_object,
      find_solr: solr_doc
    )
    create(:permission, :edit, workgroup: user.groups.first, target_druid: druid)
    sign_in(user)
  end

  context 'when the object is an item' do
    it 'renders an enabled button in the Update list' do
      get "/objects/#{druid}"

      expect(rendered_page).to have_css('h2', text: 'Update')
      expect(rendered_page).to have_css("#{button_selector}:not([disabled])", text: 'Apply APO defaults')
    end
  end

  context 'when the object is a virtual object' do
    let(:object_type) { 'virtual object' }

    it 'renders the button' do
      get "/objects/#{druid}"

      expect(rendered_page).to have_css(button_selector, text: 'Apply APO defaults')
    end
  end

  context 'when the object is a collection' do
    let(:object_type) { 'collection' }
    let(:cocina_object) { build(:collection_with_metadata, id: druid) }

    it 'renders the button' do
      get "/objects/#{druid}"

      expect(rendered_page).to have_css(button_selector, text: 'Apply APO defaults')
    end
  end

  context 'when the object is an APO' do
    let(:object_type) { 'APO' }
    let(:cocina_object) { build(:admin_policy_with_metadata, id: druid) }
    let(:solr_doc) do
      { Search::Fields::ID => druid, Search::Fields::TITLE => 'My APO', Search::Fields::OBJECT_TYPES => ['APO'],
        Search::Fields::AGREEMENT_DRUID => 'druid:hp308wm0436', Search::Fields::AGREEMENT_TITLE => 'My agreement' }
    end

    it 'does not render the button' do
      get "/objects/#{druid}"

      expect(response).to have_http_status(:ok)
      expect(rendered_page).to have_no_button('Apply APO defaults')
    end
  end

  context 'when the object is an agreement' do
    let(:object_type) { 'agreement' }
    let(:cocina_object) { build(:dro_with_metadata, id: druid, type: Cocina::Models::ObjectType.agreement) }

    it 'does not render the button' do
      get "/objects/#{druid}"

      expect(response).to have_http_status(:ok)
      expect(rendered_page).to have_no_button('Apply APO defaults')
    end
  end
end
