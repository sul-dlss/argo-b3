# frozen_string_literal: true

# Form object for registering and depositing a new Collection
# Note that this is a subclass of CocinaModels::Collection, not ApplicationForm. See README for explanation.
class NewCollectionForm < CocinaModels::Collection
  # Keeps the "collection" param key and field names (e.g., collection[title]) rather than "new_collection".
  model_name_for :collection

  include PermittedParamsConcern
  include TitleFormConcern
  include TagsFormConcern
  include CatalogRecordIdFormConcern
  include DescriptionChoiceFormConcern

  # Not permitted as params, since the collection form has no fields for them.
  # @return [Array<Symbol>]
  def self.immutable_attributes
    %i[source_id description_hash catalog_link_refresh catalog_link_part_label catalog_link_sort_key]
  end

  attribute :access_view, :string, default: 'world'
  # The spreadsheet choice of the shared description choice UI is only for items.
  validates :description_choice, inclusion: { in: [DESCRIPTION_TITLE_CHOICE, DESCRIPTION_CATALOG_ID_CHOICE] }

  # The druids of the APOs the user may select (i.e., can edit), set by the controller. Permissions do not
  # distinguish APOs from collections, so this ensures that the governing APO is an APO.
  # @return [Array<String>, nil] nil to skip the check
  attr_accessor :selectable_apo_druids

  validate :apo_druid_must_be_selectable, if: -> { selectable_apo_druids && apo_druid.present? }

  has_one :release_tags, class_name: 'CollectionReleaseTagsForm'

  # @param attributes [Hash]
  def initialize(attributes = {})
    super
    build_release_tags unless release_tags
  end

  # Registers the collection, creates its release tags, and then starts accessioning, so that the
  # release tags apply to the first deposit.
  # @param user_name [String] the sunetid of the user performing the action
  # @raise [Sdr::Repository::Error] if there is an error registering, releasing, or accessioning the collection
  # @raise [ActiveModel::ValidationError] if the form is invalid
  def create!(user_name:)
    super

    release_tags.create!(druid:, user_name:)
    Sdr::Repository.accession(cocina_object: previous_cocina_object, user_name:)
  end

  private

  def apo_druid_must_be_selectable
    return if selectable_apo_druids.include?(apo_druid)

    errors.add(:apo_druid, I18n.t('edit.collections.fields.apo_druid.validations.not_selectable'))
  end
end
