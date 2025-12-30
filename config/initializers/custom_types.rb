# frozen_string_literal: true

# ActiveModel type for handling uploaded files in forms
# Explicitly defining because mechanism for determining permitted params assumes that an
# attribute without a type is an array.
class UploadedFileType < ActiveModel::Type::Value
  def cast(value)
    return nil if value.nil?
    return value if value.is_a?(ActionDispatch::Http::UploadedFile) || value.is_a?(Rack::Test::UploadedFile)

    # Return nil or raise an error for invalid types
    nil
  end

  def serialize(value)
    value
  end

  def type
    :uploaded_file
  end
end

ActiveModel::Type.register(:uploaded_file, UploadedFileType)
