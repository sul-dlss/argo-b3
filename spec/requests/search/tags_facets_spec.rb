# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Tags facets', :solr do
  before do
    create(:solr_item, :with_tags)
  end

  describe 'index' do
    it 'returns facet values' do
      get search_tag_facets_path, params: { query: 'test' }
      expect(response).to have_http_status(:ok)
      expect(response.body).to include('turbo-frame id="tags-facet"')
      expect(response.body).to include('Tag 1')
    end
  end

  describe 'children' do
    it 'returns child facet values' do
      get children_search_tag_facets_path, params: { query: 'test', parent_value: 'Tag 2' }

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('turbo-frame id="children-of-tag-2"')
      expect(response.body).to include('Tag 2a')
    end
  end

  describe 'search' do
    it 'returns search results' do
      get search_search_tag_facets_path, params: { query: 'test', q: '2a' }

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('data-autocomplete-value="Tag 2 : Tag 2a"')
    end
  end
end
