# frozen_string_literal: true

module Search
  # Component for a "Back to search" button that links to the last search performed.
  class BackToSearchComponent < ApplicationComponent
    def initialize(last_search_form:)
      @last_search_form = last_search_form
      super()
    end

    def call
      render SdrViewComponents::Elements::ButtonLinkComponent.new(label: '← Back to search', classes: 'ps-0',
                                                                  variant: nil,
                                                                  link: search_path(last_search_form.attributes))
    end

    def render?
      last_search_form.present?
    end

    private

    attr_reader :last_search_form
  end
end
