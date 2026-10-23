# frozen_string_literal: true

# Concern for registration forms in which the user chooses to enter a title or to retrieve the
# description from FOLIO (see Edit::DescriptionChoiceComponent).
# Requires TitleFormConcern, CocinaModels::CatalogLinksConcern, and CatalogRecordIdFormConcern.
module DescriptionChoiceFormConcern
  extend ActiveSupport::Concern

  DESCRIPTION_TITLE_CHOICE = 'title'
  DESCRIPTION_CATALOG_ID_CHOICE = 'catalog_id'

  included do
    attribute :description_choice, :string, default: DESCRIPTION_TITLE_CHOICE

    validates :title, presence: true, if: -> { description_choice == DESCRIPTION_TITLE_CHOICE }
    validates :catalog_record_id, presence: true, if: -> { description_choice == DESCRIPTION_CATALOG_ID_CHOICE }

    before_validation :populate_description_hash_from_title, if: lambda {
      description_choice == DESCRIPTION_TITLE_CHOICE && title.present?
    }
    before_validation :populate_folio_catalog_link, if: lambda {
      description_choice == DESCRIPTION_CATALOG_ID_CHOICE && catalog_record_id.present?
    }
  end

  private

  # The description is refreshed from the catalog, so no title is set here.
  # @return [void]
  def populate_folio_catalog_link
    return if find_folio_catalog_link(catalog_record_id:)

    folio_catalog_links.new(catalog_record_id:)
    self.catalog_link_refresh = true
  end
end
