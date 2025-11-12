# frozen_string_literal: true

module Search
  # Component for displaying the search form
  class FormComponent < ViewComponent::Base
    def initialize(search_form:, url:, label:)
      @search_form = search_form
      @url = url
      @label = label
      super()
    end

    attr_reader :search_form, :url, :label
  end
end
