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
  include SelectableApoFormConcern

  # Not permitted as params, since the collection form has no fields for them.
  # @return [Array<Symbol>]
  def self.immutable_attributes
    %i[source_id description_hash catalog_link_refresh catalog_link_part_label catalog_link_sort_key]
  end

  # Entered with the title; ignored when the description is retrieved from FOLIO.
  attribute :abstract, :string
  normalizes :abstract, with: ->(abstract) { abstract.strip }

  attribute :access_view, :string, default: 'world'
  # The spreadsheet choice of the shared description choice UI is only for items.
  validates :description_choice, inclusion: { in: [DESCRIPTION_TITLE_CHOICE, DESCRIPTION_CATALOG_ID_CHOICE] }

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

  # Adds the abstract to the description built from the title.
  def populate_description_hash_from_title
    super
    return if abstract.blank?

    self.description_hash = description_hash.merge(note: [{ type: 'abstract', value: abstract }])
  end
end
