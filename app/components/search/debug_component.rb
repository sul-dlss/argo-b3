# frozen_string_literal: true

module Search
  # Component for displaying debug information about Solr search results
  class DebugComponent < ViewComponent::Base
    def initialize(search_form:, results:)
      @search_form = search_form
      @results = results
      super()
    end

    attr_reader :search_form, :results

    delegate :solr_response, to: :results

    def call
      tag.pre { JSON.pretty_generate(solr_response) }
    end

    def render?
      search_form.debug
    end
  end
end
