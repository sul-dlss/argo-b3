# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Projects facets', :solr do
  before do
    create(:solr_item, :with_projects)
  end

  describe 'index' do
    it 'returns facet values' do
      get search_project_facets_path, params: { query: 'test' }

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('turbo-frame id="projects-facet"')
      expect(response.body).to include('Project 1')
    end
  end

  describe 'children' do
    it 'returns child facet values' do
      get children_search_project_facets_path, params: { query: 'test', parent_value: 'Project 2' }

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('turbo-frame id="children-of-project-2"')
      expect(response.body).to include('Project 2a')
    end
  end

  describe 'search' do
    it 'returns search results' do
      get search_search_project_facets_path, params: { query: 'test', q: '2a' }

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('data-autocomplete-value="Project 2 : Project 2a"')
    end
  end
end
