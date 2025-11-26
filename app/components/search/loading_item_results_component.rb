# frozen_string_literal: true

module Search
  # Component for displaying a placeholder while item results are loading
  class LoadingItemResultsComponent < ApplicationComponent
    def number_of_placeholders
      3
    end

    def number_of_placeholder_rows
      # A real item result has ~10 rows of metadata, so match that here.
      10
    end
  end
end
