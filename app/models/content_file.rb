# frozen_string_literal: true

# Model for a Cocina::Models::File as it occurs within a particular ContentFileSet.
# The underlying binary (shared across ContentFileSets when the same file is referenced more than once)
# is modeled by ContentFileBinary.
class ContentFile < ApplicationRecord
  belongs_to :content_file_set
  belongs_to :content_file_binary
  positioned on: :content_file_set

  delegate :filepath, :basename, :extname, :path_parts, :size, :md5_digest, :sha1_digest,
           :file_location, :file, :filename, :mime_type, to: :content_file_binary

  # The deposit validation scope validates that the File can be updated in SDR.
  # In earlier parts of the flow for managing files, some of these fields may not be populated / in correct state.
  validates :external_identifier, presence: true, on: :deposit
end
