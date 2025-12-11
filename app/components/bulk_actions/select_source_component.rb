# frozen_string_literal: true

module BulkActions
  # Component for selecting the source of items for a bulk action.
  class SelectSourceComponent < ApplicationComponent
    def initialize(form:, search_form: nil, total_results: nil)
      @form = form
      @search_form = search_form
      @total_results = total_results
      super()
    end

    attr_reader :form, :search_form, :total_results

    def last_search?
      search_form.present?
    end
  end
end
