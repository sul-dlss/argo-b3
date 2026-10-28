# frozen_string_literal: true

# ActiveModel type for a year that a user enters (e.g., the from / to years of a year range search).
# Only a whole integer (e.g., "-10" or "2020") is a year; malformed input (e.g., "abc" or "2000x") is nil rather
# than another year (as for an integer attribute). Years are limited to MIN through MAX, so that a year range is
# bounded and oversized input does not raise.
class YearType < ActiveModel::Type::Value
  MIN = -9999
  MAX = 9999

  def type
    :year
  end

  private

  def cast_value(value)
    Integer(value.to_s.strip, 10, exception: false)&.clamp(MIN, MAX)
  end
end

ActiveModel::Type.register(:year, YearType)
