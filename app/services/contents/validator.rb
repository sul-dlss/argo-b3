# frozen_string_literal: true

module Contents
  # Validates the structure of a Content against a content type, using the validator for the content type.
  #
  # Unlike PopulatorSelector, there is no fallback when the content cannot be handled as the content type,
  # e.g., a book whose files are organized into folders is still validated as a book. The resulting errors
  # are wanted, since they tell the user that the content does not suit the content type.
  class Validator
    # The validator for content types without a validator of their own.
    DEFAULT_VALIDATOR = Contents::Validators::Default

    VALIDATORS_FOR_CONTENT_TYPES = {
      Cocina::Models::ObjectType.book => Contents::Validators::Book
    }.freeze

    def self.call(...)
      new(...).call
    end

    # @param [Content] content
    # @param [Cocina::Models::DROWithMetadata] cocina_object
    # @param [String, nil] content_type the selected content type, which may not have been saved yet;
    #   when blank, the content type of the cocina object is used
    def initialize(content:, cocina_object:, content_type: nil)
      @content = content
      @cocina_object = cocina_object
      @content_type = content_type.presence || cocina_object.type
    end

    # @return [Contents::Validators::Result]
    def call
      validator.call(content:, dark: dark?)
    end

    private

    attr_reader :content, :cocina_object, :content_type

    def validator
      VALIDATORS_FOR_CONTENT_TYPES.fetch(content_type, DEFAULT_VALIDATOR)
    end

    # Validates based on what the file access will be after any embargo is lifted.
    def dark?
      Contents::DefaultFileAccess.new(cocina_object:).dark?
    end
  end
end
