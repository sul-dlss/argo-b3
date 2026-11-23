# frozen_string_literal: true

module Elements
  # Component to display a JSON hash in a pretty format.
  # Wrapper around the @andypf/json-viewer library.
  # See https://github.com/andypf/json-viewer for more details and documentation of options.
  class JsonViewerComponent < ApplicationComponent
    # @param label [String] accessible name of the viewer, saying what the JSON is (e.g., "Cocina JSON")
    def initialize(hash:, label:, expanded: true, show_expand_buttons: true, compact: true)
      @hash = hash
      @label = label
      @expanded = expanded
      @show_expand_buttons = show_expand_buttons
      @compact = compact
      super()
    end

    attr_reader :label, :expanded, :show_expand_buttons, :compact

    def hash
      helpers.format_hash(@hash, compact:, pretty: false)
    end
  end
end
