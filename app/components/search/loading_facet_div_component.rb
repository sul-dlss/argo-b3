# frozen_string_literal: true

module Search
  # Component for a placeholder div for a loading, non-lazy sync facet
  class LoadingFacetDivComponent < ApplicationComponent
    def initialize(facet_config:)
      @facet_config = facet_config
      super()
    end

    attr_reader :facet_config

    delegate :form_field, to: :facet_config

    def id
      helpers.facet_id(form_field)
    end

    def label
      helpers.facet_label(form_field)
    end
  end
end
