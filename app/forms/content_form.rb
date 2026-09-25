# frozen_string_literal: true

# Form object for managing content
class ContentForm < ApplicationForm
  UPLOAD_FILE_LOCATION_CHOICE = 'upload'
  MOUNT_FILE_LOCATION_CHOICE = 'mount'
  GLOBUS_FILE_LOCATION_CHOICE = 'globus'

  attribute :file_location_choice, :string, default: UPLOAD_FILE_LOCATION_CHOICE
end
