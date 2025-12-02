# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Genres facets', :solr do
  before do
    create(:solr_item)
  end

  describe 'index' do
    it 'returns facet values' do
      # Normally this wouldn't be facet_page 1, but using here for simplicity.
      get search_genre_facets_path, params: { query: 'test', facet_page: 1 }

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('turbo-frame id="genres-facet-page1"')
      expect(response.body).to include('Maps')
    end
  end

  describe 'search' do
    it 'returns search results' do
      get search_search_genre_facets_path, params: { query: 'test', q: 'maps' }

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('data-autocomplete-value="Maps"')
    end
  end
end
