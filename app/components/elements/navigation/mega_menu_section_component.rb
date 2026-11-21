# frozen_string_literal: true

module Elements
  module Navigation
    # A section of links in a MegaMenuComponent, with a heading; a featured section stands out from the others.
    class MegaMenuSectionComponent < ApplicationComponent
      # A link to the current page is marked for assistive technology only.
      renders_many :links, lambda { |label:, link:|
        current = helpers.current_page?(link)
        SdrViewComponents::Elements::Navigation::DropdownLinkComponent.new(
          label:, link:,
          classes: class_names('fw-bold' => featured?),
          aria: { current: current ? 'page' : nil }
        )
      }

      def initialize(label:, featured: false)
        @label = label
        @featured = featured
        super()
      end

      attr_reader :label

      def featured?
        @featured
      end
    end
  end
end
