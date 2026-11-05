# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Show object Manage tags button' do
  include_context 'with show page object client'

  let(:druid) { 'druid:bc123df4567' }
  let(:object_type) { 'collection' }
  let(:cocina_object) { build(:collection_with_metadata, id: druid) }
  let(:user) { create(:user, :reader) }
  let(:rendered_page) { Capybara.string(response.body) }
  let(:button_selector) { "form[action='/objects/#{druid}/tags/edit'] button" }

  before do
    allow(Sdr::Repository).to receive_messages(
      lock: object_lock,
      find: cocina_object,
      find_solr: { Search::Fields::ID => druid, Search::Fields::TITLE => 'My object',
                   Search::Fields::OBJECT_TYPES => [object_type] }
    )
    sign_in(user)
  end

  context 'when the user can edit the object' do
    before { create(:permission, :edit, workgroup: user.groups.first, target_druid: druid) }

    it 'renders an enabled button and the Tags box link' do
      get "/objects/#{druid}"

      expect(rendered_page).to have_css("#{button_selector}:not([disabled])", text: 'Manage tags')
      expect(rendered_page).to have_css(".card a[href='/objects/#{druid}/tags/edit']", text: 'Manage tags')
    end
  end

  context 'when the user cannot edit the object' do
    before { create(:permission, :read_restricted, workgroup: user.groups.first, target_druid: druid) }

    it 'renders a disabled button and no Tags box link' do
      get "/objects/#{druid}"

      expect(rendered_page).to have_css("#{button_selector}[disabled]", text: 'Manage tags')
      expect(rendered_page).to have_no_css(".card a[href='/objects/#{druid}/tags/edit']")
    end
  end
end
