# frozen_string_literal: true

module CocinaObjectMutators
  # Mutator for rebuilding a Cocina DRO's structural.contains from a Content.
  class StructuralMutator
    FILE_SET_TYPE_PREFIX = 'https://cocina.sul.stanford.edu/models/resources/'

    def self.call(...)
      new(...).call
    end

    # @param cocina_object [Cocina::Models::DRO, Cocina::Models::DROWithMetadata] the Cocina object to mutate
    # @param content [Content] the Content to serialize into the Cocina object's structural.contains
    def initialize(cocina_object:, content:)
      unless cocina_object.is_a?(Cocina::Models::DRO) || cocina_object.is_a?(Cocina::Models::DROWithMetadata)
        raise ArgumentError, 'Expected a Cocina::Models::DRO or Cocina::Models::DROWithMetadata'
      end

      @cocina_object = cocina_object
      @content = content
    end

    # @return [Cocina::Models::DRO, Cocina::Models::DROWithMetadata] a new Cocina object with structural.contains
    #   rebuilt from the Content
    # @raise [ActiveRecord::RecordInvalid] if any ContentFileSet or ContentFile is not valid for the deposit context
    def call
      validate_deposit!
      cocina_object.new(structural: cocina_object.structural.new(contains: build_file_sets))
    end

    private

    attr_reader :cocina_object, :content

    def validate_deposit!
      content.content_file_sets.each do |content_file_set|
        raise ActiveRecord::RecordInvalid, content_file_set unless content_file_set.valid?(:deposit)

        content_file_set.content_files.each do |content_file|
          raise ActiveRecord::RecordInvalid, content_file unless content_file.valid?(:deposit)
        end
      end
    end

    def build_file_sets
      content.content_file_sets.map { |content_file_set| build_file_set(content_file_set) }
    end

    def build_file_set(content_file_set)
      {
        type: "#{FILE_SET_TYPE_PREFIX}#{content_file_set.file_set_type}",
        externalIdentifier: content_file_set.external_identifier,
        label: content_file_set.label,
        version: cocina_object.version,
        structural: { contains: build_files(content_file_set) }
      }
    end

    def build_files(content_file_set)
      content_file_set.content_files.map { |content_file| build_file(content_file) }
    end

    def build_file(content_file)
      {
        type: Cocina::Models::ObjectType.file,
        externalIdentifier: content_file.external_identifier,
        label: content_file.label,
        filename: content_file.filepath,
        version: cocina_object.version,
        size: content_file.size,
        hasMimeType: content_file.mime_type,
        languageTag: content_file.language_tag,
        use: content_file.use,
        sdrGeneratedText: content_file.sdr_generated_text,
        correctedForAccessibility: content_file.corrected_for_accessibility,
        hasMessageDigests: message_digests(content_file),
        access: access_props(content_file),
        administrative: administrative_props(content_file),
        presentation: presentation_props(content_file)
      }.compact
    end

    def message_digests(content_file)
      [
        { type: 'md5', digest: content_file.md5_digest },
        { type: 'sha1', digest: content_file.sha1_digest }
      ]
    end

    def access_props(content_file)
      {
        view: content_file.view,
        download: content_file.download,
        location: content_file.location
      }
    end

    def administrative_props(content_file)
      {
        publish: content_file.publish,
        sdrPreserve: content_file.preserve,
        shelve: content_file.shelve
      }
    end

    def presentation_props(content_file)
      {}.tap do |presentation|
        presentation[:height] = content_file.height
        presentation[:width] = content_file.width
      end.compact.presence
    end
  end
end
