# frozen_string_literal: true

module Searchers
  # Searcher for secondary facets
  class SecondaryFacet
    def self.call(...)
      new(...).call
    end

    # Views without item results also get the primary facets, which normally come with the items.
    # @return [Array<Search::Facets::Config>]
    def self.facet_configs_for(search_form)
      return Search::Facets::SECONDARY if search_form.item_results?

      Search::Facets::SECONDARY + Search::Facets::PRIMARY
    end

    # @param search_form [SearchForm]
    # @param user_scope [Permissions::UserScope] the permission scope of the requesting user
    def initialize(search_form:, user_scope:)
      @search_form = search_form
      @user_scope = user_scope
    end

    # @return [SearchResults::Items] search results
    def call
      SearchResults::Items.new(solr_response:, per_page: 0)
    end

    private

    attr_reader :search_form, :user_scope

    def solr_response
      Search::SolrService.post(request: solr_request)
    end

    def solr_request
      Search::ItemQueryBuilder.call(search_form:, user_scope:).merge(
        {
          rows: 0,
          'json.facet': facet_json
        }
      )
    end

    def facet_json
      Search::FacetsBuilder.call(facet_configs: self.class.facet_configs_for(search_form)).to_json
    end
  end
end
