# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Advanced search' do
  let(:query) { 'objectType_ssimdv:collection OR "Miller Library"' }

  before do
    sign_in(create(:user, :admin))
  end

  it 'renders its own input without loading search results before a query is submitted' do
    get advanced_search_path

    expect(response).to have_http_status(:ok)
    page = Capybara.string(response.body)
    expect(page).to have_field('query', type: :text)
    expect(page).to have_no_css('turbo-frame#items-search')
    expect(page).to have_css('form[action="/search"]')
  end

  it 'keeps the whole expression in one filter without selecting facets from its contents' do
    get advanced_search_path, params: { query: }

    page = Capybara.string(response.body)
    expect(page).to have_css('section[aria-label="Current Filters"] li', count: 1)
    expect(page).to have_link(query)
    expect(page).to have_css('turbo-frame#items-search[src^="/advanced_search/items?"]')
    expect(page).to have_css('turbo-frame[src^="/advanced_search/tag_facets?"]')
    expect(page).to have_no_css('turbo-frame#projects-search, turbo-frame#tags-search, turbo-frame#tickets-search')
    expect(page).to have_no_field('object_types[]', type: :hidden)
  end

  it 'redirects direct result requests back to the advanced page' do
    get advanced_search_items_path, params: { query:, page: 2 }

    expect(response).to redirect_to(advanced_search_path(query:, page: 2))
  end

  context 'with results' do
    before do
      allow(Search::SolrService).to receive(:post).and_return(
        'facets' => {},
        'response' => { 'numFound' => 51, 'start' => 0, 'docs' => [build(:solr_item, druid: 'druid:bc123df4567')] }
      )
    end

    it 'sends the advanced expression to eDisMax and retains it in pagination' do
      get advanced_search_items_path, params: { query: }, headers: { 'Turbo-Frame' => 'items-search' }

      expect(response).to have_http_status(:ok)
      expect(Search::SolrService).to have_received(:post).with(request: hash_including(q: query, defType: 'edismax',
                                                                                       mm: '0%', 'q.op': 'AND'))
      page = Capybara.string(response.body)
      pagination_link = page.find('a[href^="/advanced_search/items?"][href*="page=2"]', match: :first)
      pagination_parameters = Rack::Utils.parse_query(URI.parse(pagination_link[:href]).query)
      expect(pagination_parameters).to include('page' => '2', 'query' => query)
    end

    it 'retains the advanced parser when generating a report from the last search' do
      get advanced_search_items_path, params: { query: }, headers: { 'Turbo-Frame' => 'items-search' }
      allow(Search::SolrService).to receive(:post).and_return(+"id\ndruid:bc123df4567\n")

      post preview_report_path, params: { report: { source: 'results', fields: ['id'] }, commit: 'Preview' }

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('druid:bc123df4567')
      expect(Search::SolrService).to have_received(:post).with(
        request: hash_including(q: query, defType: 'edismax', mm: '0%', wt: :csv)
      )
    end

    it 'keeps ordinary search on DisMax even if an advanced view param is supplied' do
      get search_items_path, params: { query:, view_form: 'advanced' }, headers: { 'Turbo-Frame' => 'items-search' }

      expect(response).to have_http_status(:ok)
      expect(Search::SolrService).to have_received(:post).with(request: hash_including(q: query, defType: 'dismax'))
      expect(Search::SolrService).not_to have_received(:post).with(request: hash_including(mm: '0%'))
    end
  end
end
