# frozen_string_literal: true

module Search
  # Component to render a single field value result in search results (e.g. Projects results)
  class FieldValueResultComponent < ViewComponent::Base
    with_collection_parameter :value

    # @param value [String]
    # @param form_field [String] the form field name for building links
    # @param visible_limit [Integer, nil] results past this position are hidden until revealed
    # value_counter is the collection counter provided by with_collection_parameter
    def initialize(value:, value_counter:, form_field:, visible_limit: nil)
      @value = value
      @form_field = form_field
      @visible_limit = visible_limit
      @index = value_counter + 1
      super()
    end

    attr_reader :value, :form_field, :index, :visible_limit

    def id
      "#{form_field}-result-#{value.parameterize}"
    end

    def hidden?
      visible_limit.present? && index > visible_limit
    end

    def hidden_attributes
      return {} unless hidden?

      { class: 'd-none', data: { show_more_target: 'hidden' } }
    end

    def path
      url_for(ResultsSearchForm.new(form_field => [value]))
    end
  end
end
