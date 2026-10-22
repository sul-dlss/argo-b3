# frozen_string_literal: true

module Search
  # Component to display a single current filter applied to a search.
  # A filter has multiple values when the values of a facet are ORed.
  class CurrentFilterComponent < ViewComponent::Base
    def initialize(form_field:, values:, search_form:, facet_labels: {})
      @form_field = form_field
      @values = values
      @search_form = search_form
      @facet_labels = facet_labels
      super()
    end

    attr_reader :form_field, :values, :search_form, :facet_labels

    def label
      return values_label unless field_label?

      "#{field_label} > #{values_label}"
    end

    def remove_path
      # Some attributes (e.g., dates) are single values rather than arrays.
      remove_value = values.one? ? values.first : values
      url_for(search_form.without({ form_field => remove_value, page: nil }))
    end

    def query?
      form_field == 'query'
    end

    # Multi-Item Deposit names already say what they are, so the field label would repeat it.
    def field_label?
      !query? && !multi_item_deposit?
    end

    def multi_item_deposit?
      form_field == 'multi_item_deposit_action_ids'
    end

    private

    def values_label
      values.map { |value| value_label(value) }.join(' OR ')
    end

    def field_label
      helpers.facet_label(form_field)
    end

    def value_label(value)
      return multi_item_deposit_name(value) if multi_item_deposit?

      facet_config = Search::Facets.find_config_by_form_field(form_field)
      # Values for dynamic facets may need to be mapped to user-friendly labels.
      return helpers.facet_value_label(value) if facet_config&.dynamic_facet
      # Composite facet values are selected by id (e.g., druid), so resolve the label to display instead.
      return facet_labels.fetch(value, value) if facet_config&.composite_facet_field

      value
    end

    def multi_item_deposit_name(id)
      MultiItemDepositAction.find(id).name
    end
  end
end
