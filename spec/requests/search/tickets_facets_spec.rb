# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Tickets facets', :solr do
  before do
    create(:solr_item, ticket: 'TESTREQ-1')
  end

  describe 'index' do
    context 'without page param' do
      it 'returns the main facet frame' do
        get search_ticket_facets_path, params: { query: 'test' }
        expect(response).to have_http_status(:ok)
        expect(response.body).to include('turbo-frame id="tickets-facet"')
        expect(response.body).to include('TESTREQ-1')
      end
    end

    context 'with page param' do
      it 'returns a paged facet' do
        get search_ticket_facets_path, params: { query: 'test', facet_page: 1 }
        expect(response).to have_http_status(:ok)
        expect(response.body).not_to include('turbo-frame id="tickets-facet"')
        expect(response.body).to include('turbo-frame id="tickets-facet-page1"')
        expect(response.body).to include('TESTREQ-1')
      end
    end
  end

  describe 'search' do
    it 'returns search results' do
      get search_search_ticket_facets_path, params: { query: 'test', q: 'TESTREQ' }

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('data-autocomplete-value="TESTREQ-1"')
    end
  end
end
