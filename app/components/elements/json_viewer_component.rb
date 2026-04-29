# frozen_string_literal: true

module Elements
  # Component to display a JSON hash in a pretty format.
  # Wrapper around the @andypf/json-viewer library.
  # See https://github.com/andypf/json-viewer for more details and documentation of options.
  class JsonViewerComponent < ApplicationComponent
    def initialize(hash:, expanded: true, show_toolbar: true, show_tip: false)
      @hash = hash
      @expanded = expanded
      @show_toolbar = show_toolbar
      @show_tip = show_tip
      super()
    end

    attr_reader :hash, :expanded, :show_toolbar, :show_tip
  end
end
