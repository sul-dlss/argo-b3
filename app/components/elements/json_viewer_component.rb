# frozen_string_literal: true

module Elements
  # Component to display a JSON hash in a pretty format.
  # Wrapper around the @andypf/json-viewer library.
  # See https://github.com/andypf/json-viewer for more details and documentation of options.
  class JsonViewerComponent < ApplicationComponent
    def initialize(hash:, expanded: true, show_toolbar: true)
      @hash = hash
      @expanded = expanded
      @show_toolbar = show_toolbar
      super()
    end

    attr_reader :hash, :expanded, :show_toolbar
  end
end
