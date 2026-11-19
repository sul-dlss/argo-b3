# frozen_string_literal: true

# Concern for registration forms in which the user chooses to enter a title, to retrieve the
# description from FOLIO, or to upload a description spreadsheet (see Edit::DescriptionChoiceComponent).
# Requires TitleFormConcern, CocinaModels::CatalogLinksConcern, CatalogRecordIdFormConcern, and
# DescriptionCsvFormConcern.
module DescriptionChoiceFormConcern
  extend ActiveSupport::Concern

  DESCRIPTION_TITLE_CHOICE = 'title'
  DESCRIPTION_CATALOG_ID_CHOICE = 'catalog_id'
  DESCRIPTION_SPREADSHEET_CHOICE = 'spreadsheet'

  included do
    attribute :description_choice, :string, default: DESCRIPTION_TITLE_CHOICE

    validates :title, presence: true, if: -> { description_choice == DESCRIPTION_TITLE_CHOICE }
    validates :catalog_record_id, presence: true, if: -> { description_choice == DESCRIPTION_CATALOG_ID_CHOICE }
    validates :description_csv_file, presence: true, if: :description_spreadsheet_choice?
    validate :description_csv_must_be_valid, if: -> { description_spreadsheet_choice? && description_csv_file.present? }

    before_validation :populate_description_hash_from_title, if: lambda {
      description_choice == DESCRIPTION_TITLE_CHOICE && title.present?
    }
    before_validation :populate_folio_catalog_link, if: lambda {
      description_choice == DESCRIPTION_CATALOG_ID_CHOICE && catalog_record_id.present?
    }
  end

  private

  def description_spreadsheet_choice?
    description_choice == DESCRIPTION_SPREADSHEET_CHOICE
  end

  # The description is refreshed from the catalog, so no title is set here.
  # @return [void]
  def populate_folio_catalog_link
    return if find_folio_catalog_link(catalog_record_id:)

    folio_catalog_links.new(catalog_record_id:)
    self.catalog_link_refresh = true
  end
end
