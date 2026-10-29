# frozen_string_literal: true

module Search
  # Component for displaying from / to year inputs for filtering a facet by a range of years
  class FacetYearRangeComponent < ViewComponent::Base
    # @param search_form [SearchForm] The current search form
    # @param year_from_form_field [Symbol, nil] The form field for the first year of the range
    # @param year_to_form_field [Symbol, nil] The form field for the last year of the range
    def initialize(search_form:, year_from_form_field:, year_to_form_field:)
      @search_form = search_form
      @year_from_form_field = year_from_form_field
      @year_to_form_field = year_to_form_field
      super()
    end

    attr_reader :search_form, :year_from_form_field, :year_to_form_field

    def render?
      year_from_form_field.present? && year_to_form_field.present?
    end

    def year_field_options
      { class: 'form-control', min: YearType::MIN, max: YearType::MAX, step: 1 }
    end
  end
end
