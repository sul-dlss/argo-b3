# frozen_string_literal: true

module Pin
  # Renders the button for pinning or unpinning a tag.
  class PinnedTagComponent < ApplicationComponent
    # @param compact [Boolean] renders a smaller, tightly-padded button, for use in dense lists
    #   like the object show page's Tags box
    def initialize(tag:, pinned:, compact: false)
      @tag = tag
      @pinned = pinned
      @compact = compact
      super()
    end

    attr_reader :tag, :pinned, :compact

    def classes
      compact ? 'p-0' : ''
    end

    def icon_classes
      compact ? '' : 'fs-4'
    end
  end
end
