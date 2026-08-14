# Job that copies files to staging, generates fixities, determines mimetype,
# updates the object, and optionally closes version.
class StageFilesJob < ApplicationJob
  # @param [Content] content the content whose files should be staged
  # @param [String] user_id the SUNet ID of the user initiating the staging
  # @param [Boolean] accession whether to close the version and accession after staging
  def perform(content:, user_id:, accession: false)
  end
end
