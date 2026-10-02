# frozen_string_literal: true

module Search
  # Component to render a section of field value search results, e.g., the projects or tags
  # matching the query. Only the first few results are displayed; the rest are revealed by
  # a "More" link.
  class FieldValueResultsComponent < ApplicationComponent
    INITIAL_LIMIT = 5

    # @param label [String] the section label, e.g., 'Project results'
    # @param values [Enumerable<String>] the field values found by the search
    # @param form_field [String] the form field name for building links
    def initialize(label:, values:, form_field:)
      @label = label
      @values = values.to_a
      @form_field = form_field
      super()
    end

    attr_reader :label, :values, :form_field

    def render?
      values.any?
    end

    def initial_limit
      INITIAL_LIMIT
    end

    def more?
      values.size > INITIAL_LIMIT
    end
  end
end
