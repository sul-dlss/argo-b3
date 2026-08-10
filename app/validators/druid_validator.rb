# frozen_string_literal: true

# Validates that an attribute is a well-formed, prefixed druid.
class DruidValidator < ActiveModel::EachValidator
  PATTERN = /^druid:[b-df-hjkmnp-tv-z]{2}[0-9]{3}[b-df-hjkmnp-tv-z]{2}[0-9]{4}$/

  def validate_each(record, attribute, value)
    record.errors.add(attribute, 'is not a valid druid') unless PATTERN.match?(value)
  end
end
