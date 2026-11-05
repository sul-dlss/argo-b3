# frozen_string_literal: true

module Contents
  # Applies an object's access to all of its files when the object's access changes (if chosen) or is dark.
  # Cocina requires the files of a dark object to be dark and unshelved. Citation-only files become dark,
  # but keep their shelve and publish flags.
  class FileAccessOverwrite
    RIGHTS_KEYS = %i[view download location].freeze
    # Preserve is unchanged, since a file that was not preserved (e.g., a derivative) is not available to preserve.
    DARK_FLAGS = { shelve: false, publish: false }.freeze

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
      return file_access.merge(DARK_FLAGS) if object_dark?

      file_access
    end

    # Files that are left neither preserved, shelved, nor published are removed, along with resources they empty.
    # @param content [Content]
    def apply_to_content!(content)
      ActiveRecord::Base.transaction do
        content.content_files.update_all(content_file_attributes) # rubocop:disable Rails/SkipsModelValidations
        remove_unretained_content_files!(content) if object_dark?
      end
    end

    # Files that are left neither preserved, shelved, nor published are removed, along with file sets they empty.
    # @param structural_props [Hash] the props of a cocina structural, which are updated
    def apply_to_cocina_structural!(structural_props)
      file_sets_props = Array(structural_props[:contains])
      file_sets_props.each do |file_set_props|
        Array(file_set_props.dig(:structural, :contains)).each { |file_props| apply_to_cocina_file!(file_props) }
      end
      remove_unretained_cocina_files!(file_sets_props) if object_dark?
    end

    private

    attr_reader :previous_rights, :rights, :overwrite

    def apply_to_cocina_file!(file_props)
      file_props[:access] = file_access.compact
      return unless object_dark?

      file_props[:administrative] = file_props[:administrative].merge(DARK_FLAGS)
    end

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

    def remove_unretained_content_files!(content)
      unretained_content_files = ContentFile.where(content_file_set: content.content_file_sets.reorder(nil),
                                                   preserve: false, shelve: false, publish: false)
      content_file_set_ids = unretained_content_files.distinct.pluck(:content_file_set_id)
      content_file_binary_ids = unretained_content_files.distinct.pluck(:content_file_binary_id)
      unretained_content_files.find_each(&:destroy!)
      ContentFileSet.where(id: content_file_set_ids).where.missing(:content_files).find_each(&:destroy!)
      # Otherwise the binaries would be unassociated, which prevents depositing.
      Contents::ContentFileBinaryDestroyer.call(
        content_file_binaries: ContentFileBinary.where(id: content_file_binary_ids).unassociated.to_a
      )
    end

    def remove_unretained_cocina_files!(file_sets_props)
      file_sets_props.reject! do |file_set_props|
        files_props = file_set_props.dig(:structural, :contains)
        next false if files_props.blank?

        files_props.reject! do |file_props|
          file_props[:administrative].values_at(:sdrPreserve, :shelve, :publish).none?
        end
        files_props.empty?
      end
    end
  end
end
