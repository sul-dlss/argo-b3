# frozen_string_literal: true

module Pin
  # Renders the button for pinning or unpinning a search.
  class PinnedSearchComponent < ApplicationComponent
    def initialize(search_form:, pinned:)
      @search_form = search_form
      @pinned = pinned
      super()
    end

    attr_reader :search_form, :pinned

    def search_form_md5
      PinnedSearch.md5_for(search_form.attributes)
    end
  end
end
