# frozen_string_literal: true

# Concern for a form that refreshes an object's description from its FOLIO record, then deposits or, for an item,
# saves as a draft. Include after EditCocinaObjectFormConcern (or ContentDepositFormConcern).
module FolioRefreshFormConcern
  extend ActiveSupport::Concern
  include PermittedParamsConcern

  # Raised when the description was refreshed but the deposit couldn't be started.
  class NotDepositedError < StandardError; end

  included do
    # The title of the FOLIO record, shown to confirm it; never written to Cocina.
    # A form attribute so that a re-rendered page shows it without retrieving it again.
    attribute :retrieved_title, :string

    form_only_attributes :retrieved_title
  end

  class_methods do
    # Only the version description is changed by the user, so nothing else about the object can be changed.
    def permitted_params
      %i[version_description retrieved_title]
    end
  end

  # @return [String, nil] the FOLIO Instance HRID that the description is refreshed from
  def catalog_record_id
    folio_catalog_links.first&.catalog_record_id if catalog_link_refresh?
  end

  # Leaves the title blank if the FOLIO record can't be retrieved, so that the page can't be submitted.
  def retrieve_title
    self.retrieved_title = CatalogRepository.title(catalog_record_id:)
  rescue CatalogRepository::Error
    self.retrieved_title = nil
  end

  # A Draft keeps its description; otherwise the new version is described as refreshing from FOLIO.
  def prefill_version_description
    super
    return if version_description.present?

    self.version_description = I18n.t('edit.object_folio_refreshes.new.default_version_description')
  end

  # The description is replaced by DSA, so the object is not saved from the form.
  # @param [String] user_name the sunetid of the user performing the action
  # @param [Boolean] accession whether to deposit after refreshing
  # @raise [ActiveModel::ValidationError] if the form is invalid
  # @raise [Sdr::FolioRefreshService::Error] if DSA can't refresh the description
  # @raise [NotDepositedError] if the description was refreshed but the deposit couldn't be started
  def save!(user_name:, accession: false)
    validate!
    refreshed_cocina_object = Sdr::FolioRefreshService.call(
      cocina_object: previous_cocina_object, user_name:, version_description:,
      replace_open_version_description: true, version_service:
    )
    deposit!(cocina_object: refreshed_cocina_object, user_name:) if accession
  end

  private

  def deposit!(cocina_object:, user_name:)
    Sdr::DepositDraftService.call(cocina_object:, user_name:)
  rescue Sdr::DepositDraftService::Error, Sdr::Repository::Error => e
    raise NotDepositedError, e.message
  end
end
