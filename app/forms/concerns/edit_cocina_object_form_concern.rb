# frozen_string_literal: true

# Concern for a form that edits a saved Cocina object in a version, which it opens or describes when saving.
# Includers declare form_only_attributes and may override the private hooks below save!.
module EditCocinaObjectFormConcern
  extend ActiveSupport::Concern

  included do
    # The description of the version being saved. It is not part of the Cocina object.
    attribute :version_description, :string
    # Prefilled with the open version's description.
    validates :version_description, presence: true, if: :version_description_required?

    class_attribute :form_only_attribute_names, instance_writer: false, default: %w[version_description]
  end

  class_methods do
    # @param cocina_object [Cocina::Models::DROWithMetadata, Cocina::Models::CollectionWithMetadata,
    #   Cocina::Models::AdminPolicyWithMetadata]
    # @param version_service [Sdr::VersionService] shared with the caller, since each status lookup calls DSA
    # @return [self] the form for the edit page, prefilled with the open version's description
    def for_edit(cocina_object, version_service:)
      build_from_cocina_object(cocina_object).tap do |form|
        form.version_service = version_service
        form.prefill_version_description
      end
    end

    # @param cocina_object (see .for_edit)
    # @param version_service (see .for_edit)
    # @param params [ActionController::Parameters] the submitted form params (see PermittedParamsConcern)
    # @return [self] the form with the submitted changes
    def from_submission(cocina_object, version_service:, params:)
      build_from_cocina_object(cocina_object).tap do |form|
        form.version_service = version_service
        form.update(params)
      end
    end

    # Declares attributes that are not part of the Cocina object, so changing only them is not a change to save.
    # @param names [Array<Symbol>]
    def form_only_attributes(*names)
      self.form_only_attribute_names += names.map(&:to_s)
    end
  end

  attr_writer :version_service

  # Prefills the description of an open version for editing.
  def prefill_version_description
    self.version_description = version_service.version_description if version_service.open?
  end

  # @return [Boolean] true if the version is the first and has not yet been deposited
  def initial_version?
    version_service.open? && version_service.version == 1
  end

  def changed?
    (changed - form_only_attribute_names).any? || tracked_associations_changed?
  end

  # Opens a new version if the version is closed and saving or depositing needs one; otherwise updates the open
  # version's description if it changed. Then saves any changes and, if accessioning, starts accessioning.
  # @param [String] user_name the sunetid of the user performing the action
  # @param [Boolean] accession whether to start accessioning after saving
  # @raise [ActiveModel::ValidationError] if the form is invalid
  def save!(user_name:, accession: false)
    validate!
    around_content_save(accession:) do
      prepare_version!(user_name:, open_version: accession || open_version_on_save?)
      super(user_name:, accession:, workflow_context:)
    end
  end

  private

  # Whether to open a closed version when not accessioning.
  def open_version_on_save?
    changed?
  end

  def version_description_required?
    true
  end

  # @return [Hash] the context for the assembly workflow started by accessioning
  def workflow_context
    {}
  end

  # Wraps opening the version and saving, for forms that also update the mutable Content.
  def around_content_save(**)
    yield
  end

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
