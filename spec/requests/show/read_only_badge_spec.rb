# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Show object read-only badge' do
  include_context 'with show page object client'

  let(:druid) { 'druid:bc123df4567' }
  let(:user) { create(:user, :reader) }
  let(:rendered_page) { Capybara.string(response.body) }

  before do
    allow(Sdr::Repository).to receive_messages(
      lock: object_lock,
      find: build(:dro_with_metadata, id: druid),
      find_solr: { Search::Fields::ID => druid, Search::Fields::TITLE => 'My object',
                   Search::Fields::OBJECT_TYPES => ['item'] }
    )
    sign_in(user)
  end

  context 'when the user can edit the object' do
    before { create(:permission, :edit, workgroup: user.groups.first, target_druid: druid) }

    it 'does not render the badge' do
      get "/objects/#{druid}"

      expect(rendered_page).to have_css('h1', text: 'My object')
      expect(rendered_page).to have_no_css('.read-only-badge')
    end
  end

  context 'when the user can only read the object' do
    before { create(:permission, :read_restricted, workgroup: user.groups.first, target_druid: druid) }

    it 'renders the badge in the heading' do
      get "/objects/#{druid}"

      expect(rendered_page).to have_css('h1 .read-only-badge', text: 'Read only')
    end
  end
end
