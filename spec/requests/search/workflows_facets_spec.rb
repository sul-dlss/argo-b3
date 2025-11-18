# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Workflows facets', :solr do
  before do
    create(:solr_item, :with_workflows)
  end

  describe 'index' do
    it 'returns facet values' do
      get search_workflow_facets_path, params: { query: 'test' }

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('turbo-frame id="wps-workflows-facet"')
      expect(response.body).to include('accessionWF')
    end
  end

  describe 'children' do
    it 'returns child facet values' do
      get children_search_workflow_facets_path, params: { query: 'test', parent_value: 'accessionWF' }

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('turbo-frame id="children-of-accessionwf"')
      expect(response.body).to include('shelve')
    end
  end
end
