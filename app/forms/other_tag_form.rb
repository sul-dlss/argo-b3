# frozen_string_literal: true

# Form object for a single other tag (not project or ticket) on an item
class OtherTagForm < ApplicationForm
  VALID_TAG_PATTERN = /\A.+( : .+)+\z/

  attribute :tag, :string
  normalizes_whitespace :tag
  validates :tag, format: {
    with: VALID_TAG_PATTERN,
    message: ->(_object, _data) { I18n.t('edit.items.validations.other_tag_format') }
  }, allow_blank: true
end
