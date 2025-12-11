# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Languages facets', :solr do
  before do
    create(:solr_item)
    sign_in(create(:user))
  end

  describe 'index' do
    it 'returns facet values' do
      # Normally this wouldn't be facet_page 1, but using here for simplicity.
      get search_language_facets_path, params: { query: 'test', facet_page: 1 }

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('turbo-frame id="languages-facet-page1"')
      expect(response.body).to include('English')
    end
  end

  describe 'search' do
    it 'returns search results' do
      get search_search_language_facets_path, params: { query: 'test', q: 'English' }

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('data-autocomplete-value="English"')
    end
  end
end
