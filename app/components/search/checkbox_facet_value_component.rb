# frozen_string_literal: true

module Search
  # Component for displaying a single facet value as a checkbox that updates the search when changed
  class CheckboxFacetValueComponent < FacetValueComponent
    # @param description_id [String] id of the element describing what changing the checkbox does
    def initialize(description_id:, **)
      @description_id = description_id
      super(**)
    end

    attr_reader :description_id

    def id
      helpers.facet_id(form_field, suffix: "value-#{Digest::SHA256.hexdigest(value)[0, 12]}")
    end

    def toggle_path
      selected? ? remove_path : select_path
    end

    def label_classes
      class_names('form-check-label', selected: selected?)
    end
  end
end
