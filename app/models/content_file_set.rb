# frozen_string_literal: true

# Model for a Cocina::Models::FileSet
class ContentFileSet < ApplicationRecord
  belongs_to :content
  positioned on: :content
  has_many :content_files, -> { order(:position) }, inverse_of: :content_file_set, dependent: :destroy

  # The deposit validation scope validates that the FileSet can be updated in SDR.
  # In earlier parts of the flow for managing files, this field may not be populated.
  validates :external_identifier, presence: true, on: :deposit
end
