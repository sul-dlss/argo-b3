# frozen_string_literal: true

module Contents
  # Builds a Content (with its ContentFileSets and ContentFiles) from a Cocina object's structural metadata.
  class Builder
    FILE_SET_TYPE_PREFIX = 'https://cocina.sul.stanford.edu/models/resources/'

    # Adding in batches with insert_all! is much faster than individual creates.
    BATCH_SIZE = 1000

    def self.call(...)
      new(...).call
    end

    # @param cocina_object [Cocina::Models::DROWithMetadata] the Cocina object to build Content for
    def initialize(cocina_object:)
      @cocina_object = cocina_object
    end

    # @return [Content] the persisted Content built from the Cocina object's structural metadata
    def call
      # `insert_all` is being used for efficient DB updates (instead of many small updates)
      ActiveRecord::Base.transaction do
        content = Content.create!(druid: cocina_object.externalIdentifier, lock: cocina_object.lock)
        file_set_pairs = build_content_file_sets(content:)
        build_content_files(file_set_pairs:)
        content
      end
    end

    private

    attr_reader :cocina_object

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

    def build_content_files(file_set_pairs:)
      attrs = file_set_pairs.flat_map do |cocina_file_set, content_file_set_id|
        Array(cocina_file_set.structural&.contains).each_with_index.map do |cocina_file, index|
          content_file_attrs(content_file_set_id:, cocina_file:, position: index + 1)
        end
      end

      return if attrs.empty?

      attrs.each_slice(BATCH_SIZE) do |batch|
        ContentFile.insert_all!(batch) # rubocop:disable Rails/SkipsModelValidations
      end
    end

    def content_file_attrs(content_file_set_id:, cocina_file:, position:)
      {
        content_file_set_id:,
        position:,
        file_location: 'deposited',
        label: cocina_file.label,
        filepath: cocina_file.filename,
        external_identifier: cocina_file.externalIdentifier,
        size: cocina_file.size,
        mime_type: cocina_file.hasMimeType,
        language_tag: cocina_file.languageTag,
        use: cocina_file.use,
        sdr_generated_text: cocina_file.sdrGeneratedText,
        corrected_for_accessibility: cocina_file.correctedForAccessibility,
        **filepath_attributes(filepath: cocina_file.filename),
        **message_digest_attributes(cocina_file:),
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
