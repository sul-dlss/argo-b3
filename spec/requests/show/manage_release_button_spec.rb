# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Show object Manage release button' do
  include_context 'with show page object client'

  let(:druid) { 'druid:bc123df4567' }
  let(:object_type) { 'item' }
  let(:access_rights) { ['world'] }
  let(:cocina_object) { build(:dro_with_metadata, id: druid) }
  let(:user) { create(:user, :reader) }
  let(:rendered_page) { Capybara.string(response.body) }
  let(:button_selector) { "form[action='/items/#{druid}/releases/new'] button" }

  before do
    allow(Sdr::Repository).to receive_messages(
      lock: object_lock,
      find: cocina_object,
      find_solr: { Search::Fields::ID => druid, Search::Fields::TITLE => 'My object',
                   Search::Fields::OBJECT_TYPES => [object_type], Search::Fields::ACCESS_RIGHTS => access_rights }
    )
    sign_in(user)
  end

  context 'when the user can release an item' do
    before { create(:permission, :edit, workgroup: user.groups.first, target_druid: druid) }

    it 'renders an enabled button' do
      get "/objects/#{druid}"

      expect(rendered_page).to have_css("#{button_selector}:not([disabled])", text: 'Manage release')
      expect(rendered_page).to have_css(".card a[href='/items/#{druid}/releases/new']", text: 'Manage release')
    end
  end

  context 'when the user can release a virtual object' do
    let(:object_type) { 'virtual object' }

    before { create(:permission, :edit, workgroup: user.groups.first, target_druid: druid) }

    it 'renders an enabled button' do
      get "/objects/#{druid}"

      expect(rendered_page).to have_css("#{button_selector}:not([disabled])", text: 'Manage release')
    end
  end

  context 'when the item is dark' do
    let(:access_rights) { ['dark'] }

    before { create(:permission, :edit, workgroup: user.groups.first, target_druid: druid) }

    it 'renders a disabled button' do
      get "/objects/#{druid}"

      expect(rendered_page).to have_css("#{button_selector}[disabled]", text: 'Manage release')
    end
  end

  context 'when the user cannot release an item' do
    before { create(:permission, :read_restricted, workgroup: user.groups.first, target_druid: druid) }

    it 'renders a disabled button' do
      get "/objects/#{druid}"

      expect(rendered_page).to have_css("#{button_selector}[disabled]", text: 'Manage release')
    end
  end

  context 'when the object is a collection' do
    let(:object_type) { 'collection' }
    let(:cocina_object) { build(:collection_with_metadata, id: druid) }

    before { create(:permission, :edit, workgroup: user.groups.first, target_druid: druid) }

    it 'renders a disabled button' do
      get "/objects/#{druid}"

      expect(rendered_page).to have_css("#{button_selector}[disabled]", text: 'Manage release')
    end
  end

  context 'when the object is an agreement' do
    let(:object_type) { 'agreement' }

    before { create(:permission, :edit, workgroup: user.groups.first, target_druid: druid) }

    it 'does not render the button' do
      get "/objects/#{druid}"

      expect(response).to have_http_status(:ok)
      expect(rendered_page).to have_no_button('Manage release')
    end
  end
end
