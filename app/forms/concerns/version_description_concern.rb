# frozen_string_literal: true

# Concern for a Cocina form that describes the version being saved: opening a new version with the description
# if the version is closed, and otherwise updating the description of the open version.
module VersionDescriptionConcern
  extend ActiveSupport::Concern

  included do
    # The description of the version being saved. It is not part of the Cocina object.
    attribute :version_description, :string
  end

  # Lets a caller share its version service, since each status lookup calls DSA.
  attr_writer :version_service

  # Prefills the description of an open version for editing.
  def prefill_version_description
    self.version_description = version_service.version_description if version_service.open?
  end

  # @return [Boolean] true if the version is the first and has not yet been deposited
  def initial_version?
    version_service.open? && version_service.version == 1
  end

  private

  # @param [String] user_name the sunetid of the user performing the action
  # @param [Boolean] open_version whether to open a new version if the version is closed
  def prepare_version!(user_name:, open_version:)
    if version_service.open?
      # Opening a version sets its description, so only the description of an already open version is updated.
      update_version_description!(user_name:) if version_description_changed_from_open_version?
    elsif open_version
      open_version!(user_name:)
    end
  end

  # A blank description (e.g., not submitted for the initial version) does not replace the open version's.
  def version_description_changed_from_open_version?
    version_description.present? && version_description != version_service.version_description
  end

  def open_version!(user_name:)
    opened_cocina_object = Sdr::VersionService.open(druid:, description: version_description,
                                                    opening_user_name: user_name)
    # Rebase on the opened cocina object so that saving does not report a version mismatch.
    refresh_cocina_object(opened_cocina_object)
  end

  def update_version_description!(user_name:)
    version_service.update_description(description: version_description, user_name:)
  end

  def version_service
    @version_service ||= Sdr::VersionService.new(druid:)
  end
end
