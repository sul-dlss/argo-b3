# frozen_string_literal: true

module Show
  # Component for rendering the tags box on the show page.
  class TagComponent < ApplicationComponent
    include FacetedTagLinkConcern

    def initialize(tags:, pinned_tags:)
      @tags = tags
      @pinned_tags = pinned_tags
      super()
    end

    attr_reader :tags, :pinned_tags

    def pinned?(tag)
      pinned_tags.include?(tag)
    end
  end
end
