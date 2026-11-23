# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Dashboard accessibility' do
  let(:user) { create(:user) }
  let(:solr_doc) do
    {
      Search::Fields::ID => 'druid:bc123df4567',
      Search::Fields::TITLE => 'The pinned item title',
      Search::Fields::OBJECT_TYPES => ['item'],
      Search::Fields::COLLECTION_DRUIDS => ['druid:df567gh8901'],
      Search::Fields::COLLECTION_TITLES => ['The pinned item collection'],
      Search::Fields::APO_DRUID => 'druid:fg789jm0123',
      Search::Fields::APO_TITLE => ['The pinned item APO']
    }
  end

  before do
    create(:pinned_object, user:, druid: 'druid:bc123df4567')
    sign_in(user)
    allow(Searchers::ItemByDruid).to receive(:call).and_return([SearchResults::Item.new(solr_doc:)])
  end

  it 'exposes a single collection as a link, not a one-item list' do
    visit root_path

    expect(page).to have_css('table[aria-label="Pinned items"]')
    expect(accessibility_node('table[aria-label="Pinned items"] tbody td:nth-child(3)'))
      .to include(role: 'cell', name: 'The pinned item collection', child_roles: ['link'])
  end
end
