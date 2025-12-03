# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Topics facets', :solr do
  before do
    create(:solr_item)
  end

  describe 'index' do
    it 'returns facet values' do
      # Normally this wouldn't be facet_page 1, but using here for simplicity.
      get search_topic_facets_path, params: { query: 'test', facet_page: 1 }

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('turbo-frame id="topics-facet-page1"')
      expect(response.body).to include('Marching bands')
    end
  end

  describe 'search' do
    it 'returns search results' do
      get search_search_topic_facets_path, params: { query: 'test', q: 'marching' }

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('data-autocomplete-value="Marching bands"')
    end
  end
end
