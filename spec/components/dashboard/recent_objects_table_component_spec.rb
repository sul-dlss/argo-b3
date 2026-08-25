# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Dashboard::RecentObjectsTableComponent, type: :component do
  include Rails.application.routes.url_helpers

  let(:component) { described_class.new(recent_object_docs:) }
  let(:druid) { 'druid:bc123df4567' }
  let(:object_doc) do
    SearchResults::Item.new(solr_doc: {
                              Search::Fields::ID => druid,
                              Search::Fields::TITLE => 'Liver and bacon: fox trot',
                              Search::Fields::OBJECT_TYPES => ['item'],
                              Search::Fields::OTHER_TAGS => ['Project : Riegler-Deutsch Index', 'Remediated']
                            })
  end

  context 'when objects have been viewed' do
    let(:recent_object_docs) { [object_doc] }

    it 'renders the recent objects' do
      render_inline(component)

      table = page.find('table[aria-label="Recent objects"]')
      expect(table).to have_css('caption', text: 'Recent objects')
      expect(table).to have_css('th', text: 'Title')
      expect(table).to have_css('th', text: 'Druid')
      expect(table).to have_css('th', text: 'Object type')
      expect(table).to have_css('th', text: 'Tags')

      cells = table.find('tbody tr').all('td')
      expect(cells[0]).to have_link('Liver and bacon: fox trot', href: object_path(druid:))
      expect(cells[0].find('a')['data-turbo-prefetch']).to eq('false')
      expect(cells[1]).to have_text('bc123df4567')
      expect(cells[2]).to have_text('Item')
      expect(cells[3]).to have_text('Project : Riegler-Deutsch Index')
      expect(cells[3]).to have_text('Remediated')
    end
  end

  context 'when no objects have been viewed' do
    let(:recent_object_docs) { [] }

    it 'renders the empty message' do
      render_inline(component)

      expect(page).to have_text('No objects have been viewed')
    end
  end
end
