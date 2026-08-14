# frozen_string_literal: true

module Contents
  # Builds a Content (with its ContentFileSets, ContentFileBinaries, and ContentFiles) from a Cocina
  # object's structural metadata. Cocina files that share the same filename within the Content are
  # deduplicated into a single ContentFileBinary, referenced by multiple ContentFiles.
  class Builder
    FILE_SET_TYPE_PREFIX = 'https://cocina.sul.stanford.edu/models/resources/'

    # Adding in batches with insert_all! is much faster than individual creates.
    BATCH_SIZE = 1000

    def self.call(...)
      new(...).call
    end

    # @param cocina_object [Cocina::Models::DROWithMetadata] the Cocina object to build Content for
    # @param immutable [Boolean] true if the Content should be marked as non-changing
    def initialize(cocina_object:, immutable: true)
      @cocina_object = cocina_object
      @immutable = immutable
    end

    # @return [Content] the persisted Content built from the Cocina object's structural metadata
    def call
      # `insert_all` is being used for efficient DB updates (instead of many small updates)
      ActiveRecord::Base.transaction do
        content = Content.create!(druid: cocina_object.externalIdentifier, lock: cocina_object.lock, immutable:)
        file_set_pairs = build_content_file_sets(content:)
        binary_ids_by_filepath = build_content_file_binaries(content:, file_set_pairs:)
        build_content_files(file_set_pairs:, binary_ids_by_filepath:)
        content
      end
    end

    private

    attr_reader :cocina_object, :immutable

    def cocina_file_sets
      Array(cocina_object.structural&.contains)
    end

    # @return [Array<Array(Cocina::Models::FileSet, Integer)>] each cocina file set paired with the id of its
    #   newly-inserted ContentFileSet
    def build_content_file_sets(content:)
      return [] if cocina_file_sets.empty?

      attrs = cocina_file_sets.each_with_index.map do |cocina_file_set, index|
        content_file_set_attrs(content:, cocina_file_set:, position: index + 1)
      end

      ids = attrs.each_slice(BATCH_SIZE).flat_map do |batch|
        ContentFileSet.insert_all!(batch, returning: [:id]).rows.flatten # rubocop:disable Rails/SkipsModelValidations
      end

      cocina_file_sets.zip(ids) # Pairs id with cocina file
    end

    def content_file_set_attrs(content:, cocina_file_set:, position:)
      {
        content_id: content.id,
        position:,
        file_set_type: cocina_file_set.type.delete_prefix(FILE_SET_TYPE_PREFIX),
        label: cocina_file_set.label,
        external_identifier: cocina_file_set.externalIdentifier
      }
    end

    # @return [Hash<String, Integer>] the id of the newly-inserted ContentFileBinary for each distinct filename
    #   referenced by the Cocina object's file sets
    def cocina_files_by_filepath(file_set_pairs:)
      file_set_pairs.each_with_object({}) do |(cocina_file_set, _id), memo|
        Array(cocina_file_set.structural&.contains).each do |cocina_file|
          memo[cocina_file.filename] ||= cocina_file
        end
      end
    end

    def build_content_file_binaries(content:, file_set_pairs:)
      cocina_files_by_filepath = cocina_files_by_filepath(file_set_pairs:)

      return {} if cocina_files_by_filepath.empty?

      filepaths = cocina_files_by_filepath.keys
      attrs = cocina_files_by_filepath.map do |filepath, cocina_file|
        content_file_binary_attrs(content:, filepath:, cocina_file:)
      end

      ids = attrs.each_slice(BATCH_SIZE).flat_map do |batch|
        ContentFileBinary.insert_all!(batch, returning: [:id]).rows.flatten # rubocop:disable Rails/SkipsModelValidations
      end

      filepaths.zip(ids).to_h
    end

    def content_file_binary_attrs(content:, filepath:, cocina_file:)
      {
        content_id: content.id,
        file_location: 'deposited',
        filepath:,
        **filepath_attributes(filepath:),
        **message_digest_attributes(cocina_file:),
        size: cocina_file.size
      }
    end

    def build_content_files(file_set_pairs:, binary_ids_by_filepath:)
      attrs = file_set_pairs.flat_map do |cocina_file_set, content_file_set_id|
        Array(cocina_file_set.structural&.contains).each_with_index.map do |cocina_file, index|
          content_file_binary_id = binary_ids_by_filepath.fetch(cocina_file.filename)
          content_file_attrs(content_file_set_id:, content_file_binary_id:, cocina_file:, position: index + 1)
        end
      end

      return if attrs.empty?

      attrs.each_slice(BATCH_SIZE) do |batch|
        ContentFile.insert_all!(batch) # rubocop:disable Rails/SkipsModelValidations
      end
    end

    def content_file_attrs(content_file_set_id:, content_file_binary_id:, cocina_file:, position:)
      {
        content_file_set_id:,
        content_file_binary_id:,
        position:,
        label: cocina_file.label,
        external_identifier: cocina_file.externalIdentifier,
        mime_type: cocina_file.hasMimeType,
        language_tag: cocina_file.languageTag,
        use: cocina_file.use,
        sdr_generated_text: cocina_file.sdrGeneratedText,
        corrected_for_accessibility: cocina_file.correctedForAccessibility,
        **access_attributes(cocina_file:),
        **administrative_attributes(cocina_file:),
        **presentation_attributes(cocina_file:)
      }
    end

    def filepath_attributes(filepath:)
      {
        basename: FilenameSupport.basename(filepath:),
        extname: FilenameSupport.extname(filepath:),
        path_parts: FilenameSupport.path_parts(filepath:)
      }
    end

    def message_digest_attributes(cocina_file:)
      {
        md5_digest: message_digest(cocina_file:, type: 'md5'),
        sha1_digest: message_digest(cocina_file:, type: 'sha1')
      }
    end

    def message_digest(cocina_file:, type:)
      cocina_file.hasMessageDigests.find { |digest| digest.type == type }&.digest
    end

    def access_attributes(cocina_file:)
      {
        view: cocina_file.access.view,
        download: cocina_file.access.download,
        location: cocina_file.access.location
      }
    end

    def administrative_attributes(cocina_file:)
      {
        publish: cocina_file.administrative.publish,
        preserve: cocina_file.administrative.sdrPreserve,
        shelve: cocina_file.administrative.shelve
      }
    end

    def presentation_attributes(cocina_file:)
      {
        height: cocina_file.presentation&.height,
        width: cocina_file.presentation&.width
      }
    end
  end
end
