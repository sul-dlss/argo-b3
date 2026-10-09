# frozen_string_literal: true

module Contents
  # The access that a Content's files get from the object: its access after any embargo is lifted,
  # with citation-only treated as dark (files do not support citation-only access).
  class DefaultFileAccess
    # @param [Cocina::Models::DRO] cocina_object
    def initialize(cocina_object:)
      @access = cocina_object.access.embargo.presence || cocina_object.access
    end

    # @return [Hash] view, download, and location for a ContentFile
    def attributes
      { view:, download: access.download, location: access.location }
    end

    def view
      access.view == 'citation-only' ? 'dark' : access.view
    end

    def dark?
      view == 'dark'
    end

    private

    attr_reader :access
  end
end
