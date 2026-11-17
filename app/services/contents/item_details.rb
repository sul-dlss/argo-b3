# frozen_string_literal: true

module Contents
  # The item details chosen while managing files (see ContentsItemForm), saved with the mutable Content until they
  # are saved to the object.
  class ItemDetails
    ATTRIBUTES = %w[content_type viewing_direction with_embargo embargo_release_date access_view
                    access_download access_location embargo_view embargo_download embargo_location
                    overwrite_file_access version_description].freeze

    # @param content [Content] the mutable Content
    def initialize(content:)
      @content = content
    end

    # Item details are saved once a step is left, so none are saved before then.
    # @return [Hash] the saved item details as ContentsItemForm params, or empty if none are saved
    def params
      return {} if content.content_type.nil?

      content.attributes.slice(*ATTRIBUTES).symbolize_keys
    end

    # Saves the item details and text extraction settings, without saving them to the object.
    # @param form [ContentsItemForm]
    # @param other_attributes [Hash] other attributes of the content to update, e.g., the step
    def save!(form, **other_attributes)
      content.update!(**form.attributes.slice(*ATTRIBUTES), **form.text_extraction_settings_attributes,
                      **other_attributes)
    end

    # Keeps the text extraction settings, which are not item details.
    # @param other_attributes [Hash] other attributes of the content to update, e.g., the step
    def clear!(**other_attributes)
      content.update!(**ATTRIBUTES.index_with(nil), **other_attributes)
    end

    # Structuring and validating the structure use the selected access, which may not have been saved yet.
    # @param cocina_object [Cocina::Models::DROWithMetadata] the saved object
    # @return [Cocina::Models::DROWithMetadata] the object with the selected access, if any
    def apply_selected_access(cocina_object)
      ApplySelectedAccess.call(cocina_object:, params:)
    end

    # @param cocina_object [Cocina::Models::DROWithMetadata] the saved object
    # @return [String] the selected content type, which may not have been saved yet
    def selected_content_type(cocina_object)
      content.content_type || cocina_object.type
    end

    private

    attr_reader :content
  end
end
