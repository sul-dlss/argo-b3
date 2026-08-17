# frozen_string_literal: true

# Model for the binary content shared by a file, which may be referenced by multiple ContentFileSets
# (via ContentFile) within the same Content.
class ContentFileBinary < ApplicationRecord
  before_save :set_filepath_parts

  belongs_to :content
  has_many :content_files, inverse_of: :content_file_binary, dependent: :destroy

  has_one_attached :file

  # Note that the flow of a file to different locations is: attached or globus or mount -> stage -> deposited
  enum :file_location,
       {
         attached: 'attached', # File is attached to this record as an Active Storage Blob.
         deposited: 'deposited', # File has already been accessioned and stored in preservation / stacks.
         globus: 'globus', # File is on globus storage.
         stage: 'stage', # File has been moved to staging storage (and therefore ready for accessioning).
         mount: 'mount' # File is located on a mount.
       },
       prefix: true

  # The deposit validation scope validates that the binary can be updated in SDR.
  # In earlier parts of the flow for managing files, some of these fields may not be populated / in correct state.
  validates :size, :md5_digest, :sha1_digest, :mime_type, presence: true, on: :deposit
  validates :file_location, inclusion: { in: %w[stage deposited] }, on: :deposit

  def filename
    FilenameSupport.filename(filepath:)
  end

  def filepath_on_disk
    # Globus and mount to be added.
    ActiveStorageSupport.filepath_for_blob(file.blob)
  end

  private

  def set_filepath_parts
    self.path_parts = FilenameSupport.path_parts(filepath:)
    self.basename = FilenameSupport.basename(filepath:)
    self.extname = FilenameSupport.extname(filepath:)
  end
end
