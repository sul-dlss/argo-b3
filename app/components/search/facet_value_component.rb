# frozen_string_literal: true

module Search
  # Component for displaying a single facet value in a search facet
  class FacetValueComponent < ViewComponent::Base
    def initialize(count:, search_form:, form_field:, value:, exclude_form_field: nil, label: nil, **link_args) # rubocop:disable Metrics/ParameterLists
      @label = label || value
      @count = count
      @search_form = search_form
      @form_field = form_field
      @exclude_form_field = exclude_form_field
      @value = value
      @link_args = link_args
      super()
    end

    attr_reader :count, :search_form, :form_field, :value, :link_args, :exclude_form_field

    def label
      return "#{@label} exclude" if exclude_selected?

      @label
    end

    def selected?
      search_form.selected?(key: form_field, value:)
    end

    def exclude_selected?
      with_exclude? && search_form.selected?(key: exclude_form_field, value:)
    end

    def with_exclude?
      exclude_form_field.present?
    end

    def remove_title
      "Remove #{label}"
    end

    def exclude_title
      "Exclude #{@label}"
    end

    def remove_path
      remove_form_field = exclude_selected? ? exclude_form_field : form_field
      search_path(search_form.without_attributes({ remove_form_field => value, page: nil }))
    end
  end
end
