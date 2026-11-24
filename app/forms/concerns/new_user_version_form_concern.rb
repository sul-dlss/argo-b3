# frozen_string_literal: true

# Concern for a form that deposits an Item and asks whether depositing creates a new User Version, which keeps the
# previous User Version on PURL. Otherwise depositing moves the latest User Version to the new Version.
# The choice is not saved, so it is made each time the Item is deposited.
# Requires dark_access? and initial_version? (e.g., from CocinaModels::Dro and EditCocinaObjectFormConcern).
module NewUserVersionFormConcern
  extend ActiveSupport::Concern

  included do
    attribute :new_user_version, :boolean, default: false
    form_only_attributes :new_user_version
  end

  # @return [Boolean] true if the form asks whether to create a new User Version (feature_flags.new_user_version):
  #   not for a first version, which has no previous User Version, nor for a dark Item, whose previous User Versions
  #   are permanently withdrawn
  def ask_new_user_version?
    Settings.feature_flags.new_user_version && !initial_version? && !dark_access?
  end

  # @return [Boolean] true if depositing creates a new User Version
  def new_user_version?
    new_user_version && ask_new_user_version?
  end

  private

  # Adds the new User Version to the context of the deposit the form starts (edit item). super is the
  # workflow_context of the concern included before this one (e.g., ContentDepositFormConcern's text extraction
  # settings), so this concern must be included after any concern that defines workflow_context. Manage files
  # deposits from StageFilesJob instead, which adds the new User Version itself.
  def workflow_context
    new_user_version? ? super.merge(Sdr::Repository::NEW_USER_VERSION_CONTEXT) : super
  end
end
