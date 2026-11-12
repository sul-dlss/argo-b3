# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Search facets', :solr do
  before do
    create(:solr_item, :with_projects, :with_tags, :with_workflows,
           apo_druid: 'druid:bc123df4567', tickets: ['TESTREQ-1'])
    sign_in(create(:user, :reader))
  end

  Search::Facets::ROUTED.each do |facet_config|
    describe facet_config.facet_resource.to_s do
      # Facet ids derive from the config's form field, e.g. wps_workflows -> wps-workflows-facet.
      let(:page_frame) { "turbo-frame id=\"#{facet_config.form_field.to_s.dasherize}-facet-page1\"" }

      it 'returns the first page of facet values in each search view' do
        get "/search/#{facet_config.facet_resource}", params: { query: 'test', facet_page: 1 }
        expect(response.body).to include(page_frame)

        get "/workflow_grid/#{facet_config.facet_resource}", params: { query: 'test', facet_page: 1 }
        expect(response.body).to include(page_frame)
      end

      if facet_config.facet_search
        it 'returns search results' do
          get "/search/#{facet_config.facet_resource}/search", params: { query: 'test', q: 'a' }

          expect(response).to have_http_status(:ok)
        end
      end
    end
  end

  describe 'a simple facet' do
    it 'returns facet values and search results' do
      get search_genre_facets_path, params: { query: 'test', facet_page: 1 }
      expect(response.body).to include('Maps')

      get search_search_genre_facets_path, params: { query: 'test', q: 'maps' }
      expect(response.body).to include('data-autocomplete-value="Maps"')
    end
  end

  describe 'a composite facet' do
    it 'displays the label and filters and searches on the druid' do
      get search_admin_policy_facets_path, params: { query: 'test', facet_page: 1 }
      expect(response.body).to include('University Archives')

      get search_search_admin_policy_facets_path, params: { query: 'test', q: 'Archives' }
      expect(response.body).to include('data-autocomplete-value="druid:bc123df4567"')
    end
  end

  describe 'a lazy facet' do
    it 'returns the facet frame without a page param' do
      get search_ticket_facets_path, params: { query: 'test' }

      expect(response.body).to include('turbo-frame id="tickets-facet"')
      expect(response.body).to include('TESTREQ-1')
    end

    it 'returns only the page with a page param' do
      get search_ticket_facets_path, params: { query: 'test', facet_page: 1 }

      expect(response.body).not_to include('turbo-frame id="tickets-facet"')
      expect(response.body).to include('turbo-frame id="tickets-facet-page1"')
    end
  end

  describe 'a hierarchical facet' do
    it 'returns the facet frame with top-level values' do
      get search_tag_facets_path, params: { query: 'test' }

      expect(response.body).to include('turbo-frame id="tags-facet"')
      expect(response.body).to include('Tag 1')
    end

    it 'returns child facet values' do
      get children_search_tag_facets_path, params: { query: 'test', parent_value: 'Tag 2' }

      expect(response.body).to include('turbo-frame id="children-of-tag-2"')
      expect(response.body).to include('Tag 2a')
    end

    it 'returns hierarchical search results' do
      get search_search_tag_facets_path, params: { query: 'test', q: '2a' }

      expect(response.body).to include('data-autocomplete-value="Tag 2 : Tag 2a"')
    end
  end

  describe 'the workflows facet' do
    it 'returns workflows and their processes' do
      get search_workflow_facets_path, params: { query: 'test' }
      expect(response.body).to include('turbo-frame id="wps-workflows-facet"')
      expect(response.body).to include('accessionWF')

      get children_search_workflow_facets_path, params: { query: 'test', parent_value: 'accessionWF' }
      expect(response.body).to include('turbo-frame id="children-of-accessionwf"')
      expect(response.body).to include('shelve')
    end
  end
end
