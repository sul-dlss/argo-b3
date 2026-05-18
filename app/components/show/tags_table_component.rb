# frozen_string_literal: true

module Show
  # Component for rendering the tags table on the show page.
  class TagsTableComponent < ApplicationComponent
    def initialize(tags:, tickets:)
      @tags = tags
      @tickets = tickets
      super()
    end

    attr_reader :tags, :tickets
  end
end
