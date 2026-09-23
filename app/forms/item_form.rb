# frozen_string_literal: true

# Form object for creating/updating an Item (DRO)
# Note that this is a subclass of CocinaModels::Dro, not ApplicationForm.
class ItemForm < CocinaModels::Dro
  include PermittedParamsConcern
  include EmbargoFormConcern
  include TitleFormConcern
  include TagsFormConcern
  include CocinaModels::CatalogRecordIdConcern

  SOURCE_ID_PROVIDED_CHOICE = 'provide'
  SOURCE_ID_GENERATE_CHOICE = 'generate'

  DESCRIPTION_TITLE_CHOICE = 'title'
  DESCRIPTION_CATALOG_ID_CHOICE = 'catalog_id'
  DESCRIPTION_SPREADSHEET_CHOICE = 'spreadsheet'

  attribute :source_id_choice, :string, default: SOURCE_ID_PROVIDED_CHOICE

  attribute :source_id_prefix, :string
  normalizes :source_id_prefix, with: ->(source_id_prefix) { source_id_prefix.strip.delete_suffix(':') }
  validates :source_id_prefix, presence: true, if: -> { source_id_choice == SOURCE_ID_GENERATE_CHOICE }

  has_one :release_tags

  # Removes the blank value submitted by the multiple select.
  normalizes_array_compact_blank :collection_druids

  attribute :description_choice, :string, default: DESCRIPTION_TITLE_CHOICE

  validates :title, presence: true, if: -> { description_choice == DESCRIPTION_TITLE_CHOICE }
  validates :catalog_record_id, presence: true, if: -> { description_choice == DESCRIPTION_CATALOG_ID_CHOICE }

  attribute :description_csv_file, :uploaded_file
  validate :description_csv_must_be_valid, if: -> { description_choice == DESCRIPTION_SPREADSHEET_CHOICE }

  before_validation :populate_description_hash_from_title, if: lambda {
    description_choice == DESCRIPTION_TITLE_CHOICE && title.present?
  }
  before_validation :populate_folio_catalog_link, if: lambda {
    description_choice == DESCRIPTION_CATALOG_ID_CHOICE && catalog_record_id.present?
  }
  before_validation :generate_source_id, if: lambda {
    source_id_choice == SOURCE_ID_GENERATE_CHOICE && source_id_prefix.present?
  }

  attribute :limit_collection_by_apo, :boolean, default: false

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

  def populate_description_hash_from_title
    self.description_hash = { title: [{ value: title }] }
  end

  # The description is refreshed from the catalog, so no title is set here.
  def populate_folio_catalog_link
    return if find_folio_catalog_link(catalog_record_id:)

    folio_catalog_links.new(catalog_record_id:)
    self.catalog_link_refresh = true
  end

  # Normalizes, validates, and imports the uploaded description spreadsheet. This is a validation rather
  # than a before_validation callback because a callback cannot add errors and the description must only
  # be imported when the spreadsheet has none.
  # Errors are reported for description_csv_file since that is the field the user provides.
  def description_csv_must_be_valid
    return errors.add(:description_csv_file, :blank) if description_csv_file.blank?

    description_csv = parsed_description_csv
    validator = DescriptiveCsv::Validator.new(description_csv)
    return add_description_csv_errors(validator.errors) unless validator.valid?

    return unless description_csv_row_count_valid?(description_csv)

    populate_description_hash_from_csv_row(description_csv.first)
  end

  # A single item is described by a single row.
  def description_csv_row_count_valid?(description_csv)
    return true if description_csv.size == 1

    validation_key = description_csv.empty? ? 'no_rows' : 'extra_rows'
    errors.add(:description_csv_file,
               I18n.t("edit.items.fields.description_csv_file.validations.#{validation_key}"))
    false
  end

  # @return [CSV::Table]
  def parsed_description_csv
    CSV.parse(CsvUpload::Normalizer.read(description_csv_file.path), headers: true)
  end

  def populate_description_hash_from_csv_row(csv_row)
    import_result = DescriptiveCsv::Import.import(csv_row:, druid: nil)
    return add_description_csv_errors(import_result.failure) if import_result.failure?

    description = import_result.value!
    # DescriptiveCsv::Validator only checks that the spreadsheet has a title column, not that the column
    # has a value, and a RequestDescription (unlike a Description) allows an empty title.
    if description.title.empty?
      return errors.add(:description_csv_file,
                        I18n.t('edit.items.fields.description_csv_file.validations.missing_title'))
    end

    self.description_hash = description.to_h
  end

  def add_description_csv_errors(messages)
    messages.each { |message| errors.add(:description_csv_file, :invalid, message:) }
  end

  def generate_source_id
    self.source_id = "#{source_id_prefix}:#{SecureRandom.uuid}"
    self.source_id_choice = SOURCE_ID_PROVIDED_CHOICE
  end
end
