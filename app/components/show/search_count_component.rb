# frozen_string_literal: true

module Show
  # Renders a count of objects as a button linking to the search that finds them, or as plain text when there are none.
  class SearchCountComponent < ApplicationComponent
    # @param count [Integer] the number of objects the search finds
    # @param noun [String] the singular name of the objects (e.g., 'item')
    # @param search_form [SearchForm] the search that finds the objects
    def initialize(count:, noun:, search_form:)
      @count = count
      @noun = noun
      @search_form = search_form
      super()
    end

    def call
      return pluralize(@count, @noun) if @count.zero?

      render SdrViewComponents::Elements::ButtonLinkComponent.new(
        label: "View #{pluralize(@count, @noun)}", variant: 'outline-primary', link: url_for(@search_form), size: :sm
      )
    end

    delegate :pluralize, to: :helpers
  end
end
