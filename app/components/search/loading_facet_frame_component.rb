# frozen_string_literal: true

module Search
  # Component for a turbo-frame for a loading, lazy async facet
  class LoadingFacetFrameComponent < ApplicationComponent
    def initialize(search_form:, facet_config:)
      @search_form = search_form
      @facet_config = facet_config
      super()
    end

    attr_reader :search_form, :facet_config

    delegate :form_field, :facet_path_helper, to: :facet_config

    def id
      helpers.facet_id(form_field)
    end

    def path
      facet_path_helper.call(search_form.with_attributes(page: nil))
    end

    def label
      helpers.facet_label(form_field)
    end
  end
end
