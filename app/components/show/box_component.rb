# frozen_string_literal: true

module Show
  # Renders the bordered box used for the summary boxes atop the show page (status, released to, tags, etc).
  class BoxComponent < ApplicationComponent
    # Rendered beside the heading (e.g., an edit button).
    renders_one :heading_action

    def initialize(heading:)
      @heading = heading
      super()
    end

    attr_reader :heading
  end
end
