# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Dashboard::PinnedVirtualObjectsTableComponent, type: :component do
  include Rails.application.routes.url_helpers

  let(:component) { described_class.new(pinned_virtual_object_docs:) }

  let(:druid) { 'druid:bc123df4567' }
  let(:collection_druid) { 'druid:cd456fg7890' }
  let(:apo_druid) { 'druid:fg123gh4567' }

  let(:virtual_object_doc) do
    SearchResults::Item.new(solr_doc: {
                              Search::Fields::ID => druid,
                              Search::Fields::TITLE => 'Liver and bacon: fox trot',
                              Search::Fields::COLLECTION_DRUIDS => [collection_druid],
                              Search::Fields::COLLECTION_TITLES => ['Riegler-Deutsch Index'],
                              Search::Fields::APO_DRUID => apo_druid,
                              Search::Fields::APO_TITLE => ['Test APO'],
                              Search::Fields::CONSTITUENTS_COUNT => 3
                            })
  end

  context 'when there are pinned virtual objects' do
    let(:pinned_virtual_object_docs) { [virtual_object_doc] }

    it 'renders a row for each pinned virtual object' do
      render_inline(component)

      table = page.find('table[aria-label="Pinned virtual objects"]')
      expect(table).to have_css('caption', text: 'Pinned virtual objects')
      expect(table).to have_css('caption .bi-pin-fill')
      expect(table).to have_css('th', text: 'Title')
      expect(table).to have_css('th', text: 'Druid')
      expect(table).to have_css('th', text: 'Collection')
      expect(table).to have_css('th', text: 'APO')
      expect(table).to have_css('th', text: '# of constituents')
      expect(table).to have_css('th', text: 'Unpin')

      row = table.find('tbody tr')
      cells = row.all('td')
      expect(cells[0]).to have_link('Liver and bacon: fox trot', href: object_path(druid:))
      expect(cells[1]).to have_text('bc123df4567')
      expect(cells[2]).to have_link('Riegler-Deutsch Index', href: object_path(druid: collection_druid))
      expect(cells[3]).to have_link('Test APO', href: object_path(druid: apo_druid))
      expect(cells[4]).to have_text('3')
      expect(cells[5]).to have_button('Unpin')
    end
  end

  context 'when there are no pinned virtual objects' do
    let(:pinned_virtual_object_docs) { [] }

    it 'renders the empty message' do
      render_inline(component)

      expect(page).to have_text('No virtual objects have been pinned.')
    end
  end
end
