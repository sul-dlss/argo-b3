# frozen_string_literal: true

module Search
  # Controller for ticket searches
  class TicketsController < SearchApplicationController
    layout false

    def index
      @tickets = Searchers::Tag.call(search_form: @search_form, field: Search::Fields::TICKETS)
    end
  end
end
