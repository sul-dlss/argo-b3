# frozen_string_literal: true

module Search
  # Component for displaying the search form
  class FormComponent < ViewComponent::Base
    def initialize(search_form:, url:)
      @search_form = search_form
      @url = url
      super()
    end

    attr_reader :search_form, :url

    def object_type_options
      [
        %w[Agreement agreement],
        %w[APO adminPolicy],
        %w[Collection collection],
        %w[Item item],
        ['Virtual object', 'virtual object']
      ]
    end
  end
end
