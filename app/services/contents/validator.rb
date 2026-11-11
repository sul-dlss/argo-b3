# frozen_string_literal: true

module Contents
  # Validates the structure of a Content against a content type, using the validator for the content type.
  #
  # Unlike PopulatorSelector, there is no fallback when the content cannot be handled as the content type,
  # e.g., a book with hierarchical filepaths is still validated as a book. The resulting errors
  # are wanted, since they tell the user that the content does not suit the content type.
  class Validator
    # The validator for content types without a validator of their own.
    DEFAULT_VALIDATOR = Contents::Validators::Default

    VALIDATORS_FOR_CONTENT_TYPES = {
      Cocina::Models::ObjectType.three_dimensional => Contents::Validators::ThreeDimensional,
      Cocina::Models::ObjectType.agreement => Contents::Validators::Agreement,
      Cocina::Models::ObjectType.book => Contents::Validators::Book,
      Cocina::Models::ObjectType.document => Contents::Validators::Document,
      Cocina::Models::ObjectType.geo => Contents::Validators::Geo,
      Cocina::Models::ObjectType.image => Contents::Validators::Image,
      Cocina::Models::ObjectType.map => Contents::Validators::Image,
      Cocina::Models::ObjectType.media => Contents::Validators::Media,
      Cocina::Models::ObjectType.object => Contents::Validators::ObjectType,
      Cocina::Models::ObjectType.webarchive_binary => Contents::Validators::ObjectType,
      Cocina::Models::ObjectType.webarchive_seed => Contents::Validators::WebarchiveSeed
    }.freeze

    # Mirrors DSA's Cocina::FileHierarchyValidator: only these content types may have hierarchical filepaths.
    HIERARCHICAL_CONTENT_TYPES = [Cocina::Models::ObjectType.object, Cocina::Models::ObjectType.geo].freeze

    def self.call(...)
      new(...).call
    end

    # @param [Content] content
    # @param [Cocina::Models::DROWithMetadata] cocina_object
    # @param [String, nil] content_type the selected content type, which may not have been saved yet;
    #   when blank, the content type of the cocina object is used
    # @param [Cocina::Models::DROAccess, nil] saved_access the object's saved access, when cocina_object has
    #   access that has not been saved yet; when nil, the access of the cocina object is used
    def initialize(content:, cocina_object:, content_type: nil, saved_access: nil)
      @content = content
      @cocina_object = cocina_object
      @content_type = content_type.presence || cocina_object.type
      @saved_access = saved_access || cocina_object.access
    end

    # @return [Contents::Validators::Result]
    def call
      validator.call(content:, dark: dark?).tap do |result|
        result.errors.concat(*shared_validators.map { |shared| shared.call(content:, dark: dark?).errors })
        result.warnings.concat(dark_published_files_warnings)
      end
    end

    private

    attr_reader :content, :cocina_object, :content_type, :saved_access

    # The agreement and dark files validators already report published files as errors.
    def dark_published_files_warnings
      return [] if content_type == Cocina::Models::ObjectType.agreement || validate_dark_files?

      Contents::Validators::DarkPublishedFiles.call(content:, dark: dark?).warnings
    end

    def validator
      VALIDATORS_FOR_CONTENT_TYPES.fetch(content_type, DEFAULT_VALIDATOR)
    end

    # The validators whose errors apply regardless of the content type's validator.
    def shared_validators
      [].tap do |validators|
        validators << Contents::Validators::HierarchicalFilepaths unless hierarchical_content_type?
        validators << Contents::Validators::DarkFiles if validate_dark_files?
      end
    end

    def hierarchical_content_type?
      HIERARCHICAL_CONTENT_TYPES.include?(content_type)
    end

    # Only an already dark object (not citation-only) is checked, since saving an object made dark overwrites
    # its files' access.
    def validate_dark_files?
      [cocina_object.access.view, saved_access.view].all?('dark')
    end

    # Validates based on the access that the files get from the object.
    def dark?
      Contents::DefaultFileAccess.new(access: cocina_object.access).dark?
    end
  end
end
