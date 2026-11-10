# frozen_string_literal: true

# Support for displaying content types.
class ContentTypeSupport
  # The user-facing name of a content type (e.g., file rather than object), falling back to the short name for
  # content types that are not selectable on a registration form.
  # @param content_type [String] the short name of the content type (e.g., object)
  # @return [String]
  def self.display_name(content_type)
    Constants::REGISTRATION_CONTENT_TYPES.key(Constants::CONTENT_TYPES[content_type]) || content_type
  end
end
