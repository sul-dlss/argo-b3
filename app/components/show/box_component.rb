# frozen_string_literal: true

module Show
  # Renders the bordered box used for the summary boxes atop the show page (status, released to, tags, etc).
  class BoxComponent < ApplicationComponent
    def initialize(heading:)
      @heading = heading
      super()
    end

    attr_reader :heading
  end
end
