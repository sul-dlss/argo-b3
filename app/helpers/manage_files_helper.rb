# frozen_string_literal: true

# The name of managing files, which the status box button, its page, and messages that mention it show:
# "Add files and deposit" until the object's first version is deposited, then "Edit files and structure".
module ManageFilesHelper
  # @param version_service [Sdr::VersionService] for the object
  # @return [String]
  def manage_files_label(version_service:)
    if version_service.first_version_deposited?
      I18n.t('edit.contents.labels.edit_files_and_structure')
    else
      I18n.t('edit.contents.labels.add_files_and_deposit')
    end
  end
end
