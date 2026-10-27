# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Show object Admin section' do
  include_context 'with show page object client'

  let(:druid) { 'druid:bc123df4567' }
  let(:object_type) { 'APO' }
  let(:user) { create(:user, groups: [AuthenticationHelpers::ADMIN_GROUP]) }
  let(:rendered_page) { Capybara.string(response.body) }

  before do
    allow(Sdr::Repository).to receive_messages(
      lock: object_lock,
      find: build(:admin_policy, id: druid),
      find_solr: { Search::Fields::ID => druid, Search::Fields::TITLE => 'My object',
                   Search::Fields::OBJECT_TYPES => [object_type],
                   Search::Fields::AGREEMENT_DRUID => 'druid:dd123fg4567',
                   Search::Fields::AGREEMENT_TITLE => 'My agreement' }
    )
    sign_in(user)
  end

  context 'when an admin views an APO' do
    it 'renders the Manage permissions button' do
      get "/objects/#{druid}"

      expect(rendered_page).to have_css('h2', exact_text: 'Admin')
      expect(rendered_page).to have_css("form[action='/admin/objects/druid:bc123df4567/permissions'] button",
                                        text: 'Manage permissions')
    end
  end

  context 'when an admin views a collection' do
    let(:object_type) { 'collection' }

    it 'renders the Manage permissions button' do
      get "/objects/#{druid}"

      expect(rendered_page).to have_css("form[action='/admin/objects/druid:bc123df4567/permissions'] button",
                                        text: 'Manage permissions')
    end
  end

  context 'when an admin views an item' do
    let(:object_type) { 'item' }

    it 'does not render the Admin section' do
      get "/objects/#{druid}"

      expect(response).to have_http_status(:ok)
      expect(rendered_page).to have_no_css('h2', exact_text: 'Admin')
      expect(rendered_page).to have_no_button('Manage permissions')
    end
  end

  context 'when a non-admin views a collection' do
    let(:object_type) { 'collection' }
    let(:user) { create(:user, groups: ['sdr:viewers']) }

    before do
      create(:permission, :read_restricted, workgroup: 'sdr:viewers', target_druid: druid)
    end

    it 'does not render the Admin section' do
      get "/objects/#{druid}"

      expect(response).to have_http_status(:ok)
      expect(rendered_page).to have_no_css('h2', exact_text: 'Admin')
      expect(rendered_page).to have_no_button('Manage permissions')
    end
  end

  context 'when a non-admin with edit permission views an APO' do
    let(:user) { create(:user, groups: ['sdr:editors']) }

    before do
      create(:permission, :edit, workgroup: 'sdr:editors', target_druid: druid)
    end

    it 'does not render the Admin section' do
      get "/objects/#{druid}"

      expect(response).to have_http_status(:ok)
      expect(rendered_page).to have_no_css('h2', exact_text: 'Admin')
      expect(rendered_page).to have_no_button('Manage permissions')
    end
  end
end
