# frozen_string_literal: true

module Pin
  # Renders the button for pinning or unpinning an object.
  class PinnedObjectComponent < ApplicationComponent
    def initialize(druid:, pinned:)
      @druid = druid
      @pinned = pinned
      super()
    end

    attr_reader :druid, :pinned
  end
end
