# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Dashboard::RecentDraftsAndDepositsTableComponent, type: :component do
  include Rails.application.routes.url_helpers

  let(:component) { described_class.new(object_docs:, statuses:, search_form:) }

  let(:druid) { 'druid:bc123df4567' }
  let(:collection_druid) { 'druid:cd456fg7890' }
  let(:search_form) do
    ResultsSearchForm.new(last_updated_by: ['jlittman'], object_types: ['item'], sort: 'last_updated_date_desc')
  end
  let(:statuses) { { druid => :staging_failed } }

  let(:object_doc) do
    SolrDocPresenter.new(solr_doc: {
                           Search::Fields::ID => druid,
                           Search::Fields::TITLE => 'Solar flare dataset',
                           Search::Fields::COLLECTION_DRUIDS => [collection_druid],
                           Search::Fields::COLLECTION_TITLES => ['Stanford Research Data'],
                           Search::Fields::LAST_UPDATED_DATE => '2026-08-31T18:00:00Z'
                         })
  end

  context 'when there are recent drafts and deposits' do
    let(:object_docs) { [object_doc] }

    it 'renders a row for each Item and a link to the complete list' do
      render_inline(component)

      table = page.find('table#recent-drafts-and-deposits-table[aria-label="Recent drafts and deposits"]')
      expect(table).to have_css('caption', text: 'Recent drafts and deposits')
      expect(table.all('thead th').map { |header| header.text.strip })
        .to eq(['Title', 'Druid', 'Collection', 'Status', 'Last updated'])

      cells = table.find('tbody tr').all('td')
      expect(cells[0]).to have_link('Solar flare dataset', href: object_path(druid:))
      expect(cells[1]).to have_text('bc123df4567')
      expect(cells[2]).to have_link('Stanford Research Data', href: object_path(druid: collection_druid))
      expect(cells[3]).to have_text('Staging failed')
      expect(cells[3]).to have_css('.text-danger')
      expect(cells[4]).to have_text('2026-08-31 11:00:00 PT')
      expect(page).to have_link('View complete list of your recent drafts and deposits',
                                href: '/search/items?last_updated_by%5B%5D=jlittman&object_types%5B%5D=item' \
                                      '&sort=last_updated_date_desc')
    end
  end

  context 'when there are no recent drafts and deposits' do
    let(:object_docs) { [] }
    let(:statuses) { {} }

    it 'does not render' do
      render_inline(component)

      expect(page).to have_no_table
      expect(page).to have_no_link('View complete list of your recent drafts and deposits')
    end
  end
end
