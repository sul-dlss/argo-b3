# frozen_string_literal: true

# Form object for editing a ContentFile (file) within a ContentFileSetForm (resource)
class ContentFileForm < ApplicationForm
  inherit_attributes_from ContentFile, only: %i[id use]
  # Stored on the ContentFileBinary, so shared by every file that references the binary.
  attribute :mime_type, :string
  # For display only; not editable.
  attribute :filepath, :string

  normalizes_whitespace :use, :mime_type

  validates :mime_type, presence: true

  def self.immutable_attributes
    [:filepath]
  end
end
