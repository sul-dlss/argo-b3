# frozen_string_literal: true

module Contents
  # The access that a Content's files get from the object: its current access (during any embargo, since
  # releasing the embargo updates the files), with citation-only treated as dark (files cannot be citation-only).
  class DefaultFileAccess
    # @param [Cocina::Models::DROAccess, Hash] access the object's access
    def initialize(access:)
      @access = access.to_h.symbolize_keys
    end

    # @return [Hash] view, download, and location for a ContentFile
    def attributes
      { view:, download: access[:download], location: access[:location] }
    end

    def view
      access[:view] == 'citation-only' ? 'dark' : access[:view]
    end

    def dark?
      view == 'dark'
    end

    private

    attr_reader :access
  end
end
