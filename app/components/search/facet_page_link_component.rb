# frozen_string_literal: true

module Search
  # Component for displaying a "More" link to the next page of a search facet
  class FacetPageLinkComponent < ViewComponent::Base
    def initialize(facet_counts:, search_form:, facet_path_helper:, form_field:)
      @facet_counts = facet_counts
      @search_form = search_form
      @facet_path_helper = facet_path_helper
      @form_field = form_field
      super()
    end

    attr_reader :facet_counts, :search_form, :facet_path_helper, :form_field

    def render?
      facet_path_helper.present? && next_page.present?
    end

    def next_page
      @next_page ||= begin
        next_page = facet_counts.page + 1
        next_page <= facet_counts.total_pages ? next_page : nil
      end
    end

    def next_page_path
      facet_path_helper.call(
        facet_page: next_page,
        **search_form.without_attributes(page: nil)
      )
    end

    def next_frame_id
      helpers.facet_id(form_field, suffix: "page#{next_page}")
    end
  end
end
