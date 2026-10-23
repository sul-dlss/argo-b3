# frozen_string_literal: true

# Form object for registering a new Item (DRO)
# Note that this is a subclass of CocinaModels::Dro, not ApplicationForm. See README for explanation.
class NewItemForm < CocinaModels::Dro
  # Keeps the "item" param key and field names (e.g., item[title]) rather than "new_item".
  model_name_for :item

  include PermittedParamsConcern
  include EmbargoFormConcern
  include TitleFormConcern
  include TagsFormConcern
  include CollectionFormConcern
  include CatalogRecordIdFormConcern
  include DescriptionCsvFormConcern
  # Provides the title and catalog id description choices; the spreadsheet choice is specific to items.
  include DescriptionChoiceFormConcern

  SOURCE_ID_PROVIDED_CHOICE = 'provide'
  SOURCE_ID_GENERATE_CHOICE = 'generate'

  DESCRIPTION_SPREADSHEET_CHOICE = 'spreadsheet'

  attribute :source_id_choice, :string, default: SOURCE_ID_PROVIDED_CHOICE

  attribute :source_id_prefix, :string
  normalizes :source_id_prefix, with: ->(source_id_prefix) { source_id_prefix.strip.delete_suffix(':') }
  validates :source_id_prefix, presence: true, if: -> { source_id_choice == SOURCE_ID_GENERATE_CHOICE }

  has_one :release_tags

  validates :description_csv_file, presence: true, if: :description_spreadsheet_choice?
  validate :description_csv_must_be_valid, if: -> { description_spreadsheet_choice? && description_csv_file.present? }

  before_validation :generate_source_id, if: lambda {
    source_id_choice == SOURCE_ID_GENERATE_CHOICE && source_id_prefix.present?
  }

  def initialize(attributes = {})
    super
    build_release_tags unless release_tags
    derive_with_embargo
  end

  def create!(user_name:)
    super

    release_tags.create!(druid:, user_name:)
  end

  private

  def description_spreadsheet_choice?
    description_choice == DESCRIPTION_SPREADSHEET_CHOICE
  end

  def generate_source_id
    self.source_id = "#{source_id_prefix}:#{SecureRandom.uuid}"
    self.source_id_choice = SOURCE_ID_PROVIDED_CHOICE
  end
end
