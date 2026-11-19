# frozen_string_literal: true

module Elements
  module Navigation
    # A header navigation dropdown whose menu is a wide panel of sections of links, laid out in columns that read
    # row by row (one column in the collapsed navigation).
    # A candidate to move into SDR View Components, alongside its DropdownMenuComponent.
    class MegaMenuComponent < ApplicationComponent
      renders_many :sections, Elements::Navigation::MegaMenuSectionComponent

      def initialize(text:)
        @text = text
        super()
      end

      attr_reader :text
    end
  end
end
