# frozen_string_literal: true

# Model for a Cocina::Models::File
class ContentFile < ApplicationRecord
  before_save :set_filepath_parts

  belongs_to :content_file_set
  positioned on: :content_file_set

  has_one_attached :file

  enum :file_location,
       {
         attached: 'attached',
         deposited: 'deposited',
         globus: 'globus',
         stage: 'stage',
         mount: 'mount'
       },
       prefix: true

  # The deposit validation scope validates that the File can be updated in SDR.
  # In earlier parts of the flow for managing files, some of these fields may not be populated / in correct state.
  validates :external_identifier, :mime_type, :size, :md5_digest, :sha1_digest, presence: true, on: :deposit
  validates :file_location, inclusion: { in: %w[stage deposited] }, on: :deposit

  def filename
    FilenameSupport.filename(filepath:)
  end

  private

  def set_filepath_parts
    self.path_parts = FilenameSupport.path_parts(filepath:)
    self.basename = FilenameSupport.basename(filepath:)
    self.extname = FilenameSupport.extname(filepath:)
  end
end
