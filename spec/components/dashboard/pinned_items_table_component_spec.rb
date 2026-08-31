# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Dashboard::PinnedItemsTableComponent, type: :component do
  include Rails.application.routes.url_helpers

  let(:component) { described_class.new(pinned_item_docs:) }

  let(:druid) { 'druid:bc123df4567' }
  let(:collection_druid) { 'druid:cd456fg7890' }
  let(:apo_druid) { 'druid:fg123gh4567' }

  let(:item_doc) do
    SearchResults::Item.new(solr_doc: {
                              Search::Fields::ID => druid,
                              Search::Fields::TITLE => 'Liver and bacon: fox trot',
                              Search::Fields::COLLECTION_DRUIDS => [collection_druid],
                              Search::Fields::COLLECTION_TITLES => ['Riegler-Deutsch Index'],
                              Search::Fields::APO_DRUID => apo_druid,
                              Search::Fields::APO_TITLE => ['Test APO']
                            })
  end

  context 'when there are pinned items' do
    let(:pinned_item_docs) { [item_doc] }

    it 'renders a row for each pinned item' do
      render_inline(component)

      table = page.find('table[aria-label="Pinned items"]')
      expect(table).to have_css('caption', text: 'Pinned items')
      expect(table).to have_css('caption .bi-pin-fill')
      expect(table).to have_css('th', text: 'Title')
      expect(table).to have_css('th', text: 'Druid')
      expect(table).to have_css('th', text: 'Collection')
      expect(table).to have_css('th', text: 'APO')
      expect(table).to have_css('th', text: 'Unpin')

      row = table.find('tbody tr')
      cells = row.all('td')
      expect(cells[0]).to have_link('Liver and bacon: fox trot', href: object_path(druid:))
      expect(cells[1]).to have_text('bc123df4567')
      expect(cells[2]).to have_css('ul li')
      expect(cells[2]).to have_link('Riegler-Deutsch Index', href: object_path(druid: collection_druid))
      expect(cells[3]).to have_link('Test APO', href: object_path(druid: apo_druid))
      expect(cells[4]).to have_button('Unpin')
    end
  end

  context 'when a pinned item has no collection' do
    let(:pinned_item_docs) { [item_doc] }

    let(:item_doc) do
      SearchResults::Item.new(solr_doc: {
                                Search::Fields::ID => druid,
                                Search::Fields::TITLE => 'Liver and bacon: fox trot',
                                Search::Fields::APO_DRUID => apo_druid,
                                Search::Fields::APO_TITLE => ['Test APO']
                              })
    end

    it 'renders an empty collection cell' do
      render_inline(component)

      row = page.find('table[aria-label="Pinned items"] tbody tr')
      cells = row.all('td')
      expect(cells[2]).to have_css('ul')
      expect(cells[2]).to have_no_css('li')
    end
  end

  context 'when there are no pinned items' do
    let(:pinned_item_docs) { [] }

    it 'renders the empty message' do
      render_inline(component)

      expect(page).to have_text('No items have been pinned.')
    end
  end
end
