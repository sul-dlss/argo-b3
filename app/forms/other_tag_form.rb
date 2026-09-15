# frozen_string_literal: true

# Form object for a single other tag (not project or ticket) on an item
class OtherTagForm < ApplicationForm
  include PrevalidationConcern

  VALID_TAG_PATTERN = /\A.+( : .+)+\z/

  attribute :tag, :string
  normalizes_whitespace :tag
  # The message is a plain string rather than a proc, since a proc option cannot be serialized by
  # FormErrorsSerializer.
  validates :tag, format: {
    with: VALID_TAG_PATTERN,
    message: 'must be a series of 2 or more strings delimited with space-padded colons'
  }, allow_blank: true
end
