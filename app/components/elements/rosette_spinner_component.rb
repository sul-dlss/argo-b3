# frozen_string_literal: true

module Elements
  # Spinner using the SDR rosette image.
  class RosetteSpinnerComponent < ApplicationComponent
    SIZES = { small: 32, large: 192 }.freeze

    # @param size [Symbol] :small or :large
    # @param spinner_options [Hash] passed to SdrViewComponents::Elements::SpinnerComponent (e.g., message:, classes:)
    def initialize(size:, **spinner_options)
      @size = SIZES.fetch(size)
      @spinner_options = spinner_options
      super()
    end

    def call
      render SdrViewComponents::Elements::SpinnerComponent.new(
        image_path: "#{SdrViewComponents.configuration.component_library_url}/styles/Rosette.svg",
        height: @size, width: @size, speed: 2.0, **@spinner_options
      )
    end
  end
end
