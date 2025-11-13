# frozen_string_literal: true

module Search
  # Component to render a single hierarchical facet value
  class HierarchicalValueComponent < ViewComponent::Base
    with_collection_parameter :facet_count

    def initialize(facet_count:, search_form:, path_helper:, form_field:)
      @facet_count = facet_count
      @path_helper = path_helper
      @search_form = search_form
      @form_field = form_field
      super()
    end

    attr_reader :facet_count, :path_helper, :search_form, :form_field

    delegate :value, :count, :value_parts, to: :facet_count

    def children_collapse_id
      "collapse-#{value.parameterize}"
    end

    def children_turbo_id
      "children-of-#{value.parameterize}"
    end

    def children_path
      path_helper.call(**search_form.with_attributes(page: nil), parent_value: value)
    end

    def style
      "margin-left: #{(facet_count.level - 1) * 15}px;"
    end

    def label
      value_parts.last
    end

    def selected?
      search_form.selected?(key: form_field, value:)
    end

    def expanded?
      # Do any of the selected values start with this value?
      search_form.public_send(form_field).any? do |selected_value|
        selected_value.start_with?(value)
      end
    end

    def collapse_classes
      "collapse#{' show' if expanded?}"
    end
  end
end
