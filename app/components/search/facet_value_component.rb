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

    attr_reader :label, :count, :search_form, :form_field, :value, :link_args, :exclude_form_field

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
      exclude_selected? ? "Remove exclude #{label}" : "Remove #{label}"
    end

    def exclude_label
      "Exclude #{label}"
    end

    # Selecting an excluded value stops excluding it.
    def select_path
      form = with_exclude? ? search_form.without({ exclude_form_field => value }) : search_form
      url_for(form.with({ form_field => [value], page: nil }))
    end

    # Excluding a selected value stops selecting it.
    def exclude_path
      url_for(search_form.without({ form_field => value }).with({ exclude_form_field => [value], page: nil }))
    end

    def remove_path
      remove_form_field = exclude_selected? ? exclude_form_field : form_field
      url_for(search_form.without({ remove_form_field => value, page: nil }))
    end

    def render_remove_link
      link_to remove_path, class: 'remove ms-2', rel: 'nofollow', title: remove_title, **link_args do
        helpers.remove_icon(classes: 'ms-2', aria: { hidden: true }) +
          tag.span("[#{remove_title}]", class: 'visually-hidden')
      end
    end

    def render_exclude_link
      render SdrViewComponents::Elements::ButtonLinkComponent.new(link: exclude_path, variant: :link, size: :sm,
                                                                  classes: 'ms-2 p-0 align-baseline', **link_args) do
        tag.span('exclude', aria: { hidden: true }) + tag.span(exclude_label, class: 'visually-hidden')
      end
    end

    def render_excluded
      tag.span(class: 'ms-2 text-nowrap') { tag.strong('excluded') + render_remove_link }
    end
  end
end
