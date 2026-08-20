# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Dashboard::PinnedCollectionsTableComponent, type: :component do
  include Rails.application.routes.url_helpers

  let(:component) { described_class.new(pinned_collection_docs:) }

  let(:druid) { 'druid:bc123df4567' }
  let(:apo_druid) { 'druid:ef123gh4567' }

  let(:collection_doc) do
    SearchResults::Item.new(solr_doc: {
                              Search::Fields::ID => druid,
                              Search::Fields::TITLE => 'Riegler-Deutsch Index',
                              Search::Fields::APO_DRUID => apo_druid,
                              Search::Fields::APO_TITLE => ['Test APO']
                            })
  end

  context 'when there are pinned collections' do
    let(:pinned_collection_docs) { [collection_doc] }

    it 'renders a row for each pinned collection' do
      render_inline(component)

      table = page.find('table[aria-label="Pinned collections"]')
      expect(table).to have_css('caption', text: 'Pinned collections')
      expect(table).to have_css('caption .bi-pin-fill')
      expect(table).to have_css('th', text: 'Title')
      expect(table).to have_css('th', text: 'Druid')
      expect(table).to have_css('th', text: 'APO')
      expect(table).to have_css('th', text: 'Unpin')
      expect(table).to have_no_css('th', text: 'Collection')

      row = table.find('tbody tr')
      cells = row.all('td')
      expect(cells[0]).to have_link('Riegler-Deutsch Index', href: object_path(druid:))
      expect(cells[1]).to have_text('bc123df4567')
      expect(cells[2]).to have_link('Test APO', href: object_path(druid: apo_druid))
      expect(cells[3]).to have_button('Unpin')
    end
  end

  context 'when there are no pinned collections' do
    let(:pinned_collection_docs) { [] }

    it 'renders the empty message' do
      render_inline(component)

      expect(page).to have_text('No collections have been pinned.')
    end
  end
end
