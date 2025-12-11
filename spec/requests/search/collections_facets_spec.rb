# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Collections facets', :solr do
  before do
    create(:solr_item)
    sign_in(create(:user))
  end

  describe 'index' do
    it 'returns facet values' do
      # Normally this wouldn't be facet_page 1, but using here for simplicity.
      get search_collection_facets_path, params: { query: 'test', facet_page: 1 }

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('turbo-frame id="collection-titles-facet-page1"')
      expect(response.body).to include('David Rumsey Map Collection')
    end
  end

  describe 'search' do
    it 'returns search results' do
      get search_search_collection_facets_path, params: { query: 'test', q: 'Rumsey' }

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('data-autocomplete-value="David Rumsey Map Collection"')
    end
  end
end
