# frozen_string_literal: true

module Search
  # Controller for ticket searches
  class TicketsController < SearchApplicationController
    layout false

    def index
      @search_form = build_form(form_class: SearchForm)
      @tickets = Searchers::Tag.call(search_form: @search_form, field: Search::Fields::TICKETS)
    end
  end
end
