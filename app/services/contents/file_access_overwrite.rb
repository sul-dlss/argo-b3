# frozen_string_literal: true

module Contents
  # Applies an object's access to all of its files when the object's access changes (if chosen) or is dark.
  # Cocina requires the files of a dark object to be dark and unshelved. Citation-only files become dark,
  # but keep their shelve and publish flags.
  class FileAccessOverwrite
    RIGHTS_KEYS = %i[view download location].freeze
    COCINA_DARK_FLAGS = Contents::FileAttributes::DARK.transform_keys(preserve: :sdrPreserve).freeze

    # @param previous_access [Cocina::Models::DROAccess] the object's saved access
    # @param access [Cocina::Models::DROAccess, Hash] the object's edited access
    # @param overwrite [Boolean] whether to overwrite the files' access when the object's access changed
    def initialize(previous_access:, access:, overwrite:)
      @previous_rights = rights_for(previous_access)
      @rights = rights_for(access)
      @overwrite = overwrite
    end

    def apply?
      object_dark? || (overwrite && rights != previous_rights)
    end

    # @return [Hash] the attributes for each ContentFile
    def content_file_attributes
      return file_access.merge(Contents::FileAttributes::DARK) if object_dark?

      file_access
    end

    # @param file_props [Hash] the props of a cocina file, which are updated
    def apply_to_cocina_file!(file_props)
      file_props[:access] = file_access.compact
      return unless object_dark?

      file_props[:administrative] = file_props[:administrative].merge(COCINA_DARK_FLAGS)
    end

    private

    attr_reader :previous_rights, :rights, :overwrite

    def file_access
      Contents::DefaultFileAccess.new(access: rights).attributes
    end

    # Only a dark object unshelves and unpublishes its files; citation-only files keep their flags.
    def object_dark?
      rights[:view] == 'dark'
    end

    def rights_for(access)
      access.to_h.symbolize_keys.slice(*RIGHTS_KEYS).compact_blank
    end
  end
end
