# frozen_string_literal: true

# Model for a Cocina::Models::FileSet
class ContentFileSet < ApplicationRecord
  MOVE_OFFSETS = { 'up' => -1, 'down' => 1 }.freeze
  MOVE_DIRECTIONS = MOVE_OFFSETS.keys.freeze

  belongs_to :content
  positioned on: :content
  has_many :content_files, -> { order(:position) }, inverse_of: :content_file_set, dependent: :destroy
  accepts_nested_attributes_for :content_files, allow_destroy: true

  validates :file_set_type, inclusion: { in: FileSetTypes::ALL }

  # The deposit validation scope validates that the FileSet can be updated in SDR.
  # In earlier parts of the flow for managing files, this field may not be populated.
  validates :external_identifier, presence: true, on: :deposit

  # Moves the file set one place up or down within its content. The positioning gem keeps the position within
  # the list (so moving the first file set up or the last one down does nothing) and shifts the neighbouring file set.
  # @param [String] direction 'up' or 'down'
  def move(direction)
    update!(position: position + MOVE_OFFSETS.fetch(direction))
  end
end
