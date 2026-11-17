# frozen_string_literal: true

module Search
  # Component for displaying the search form
  class FormComponent < ViewComponent::Base
    def initialize(current_search_form: nil, last_search_form: nil)
      @search_form = current_search_form || last_search_form
      # Advanced expressions belong in their own input, rather than the global keyword bar.
      @search_form = ResultsSearchForm.new if @search_form.nil? || @search_form.advanced?
      super()
    end

    attr_reader :search_form

    def url
      url_for(search_form)
    end
  end
end
