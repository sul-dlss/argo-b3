# frozen_string_literal: true

# Model for the binary content shared by a file, which may be referenced by multiple ContentFileSets
# (via ContentFile) within the same Content.
class ContentFileBinary < ApplicationRecord
  before_save :set_filepath_parts

  belongs_to :content
  has_many :content_files, inverse_of: :content_file_binary, dependent: :destroy

  has_one_attached :file

  # A binary that is not referenced by a ContentFile is not part of the structure of the Content.
  scope :unassociated, -> { where.missing(:content_files) }
  # distinct is necessary since a binary may be referenced by multiple files.
  scope :associated, -> { where.associated(:content_files).distinct }
  # Orders by directory, then basename (with embedded numbers ordered numerically), then extension.
  scope :path_order, -> { order(path_parts: :asc).order('basename COLLATE "numeric"').order(extname: :asc) }

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

  validates :mount_path, presence: true, if: :file_location_mount?

  def filename
    FilenameSupport.filename(filepath:)
  end

  def filepath_on_disk
    case file_location
    when 'attached'
      ActiveStorageSupport.filepath_for_blob(file.blob)
    when 'mount'
      File.join(mount_path, filepath)
    when 'globus'
      raise NotImplementedError
    else
      raise 'File is not on disk'
    end
  end

  # @return [Boolean] true if the filepath includes directories (e.g., folder1/image1.tif)
  # Note that this relies on path_parts, which is derived from the filepath when saved.
  def hierarchical?
    path_parts.any?
  end

  private

  def set_filepath_parts
    self.path_parts = FilenameSupport.path_parts(filepath:)
    self.basename = FilenameSupport.basename(filepath:)
    self.extname = FilenameSupport.extname(filepath:)
  end
end
