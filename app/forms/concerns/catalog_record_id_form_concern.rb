# frozen_string_literal: true

# Concern for forms rendered with Edit::CatalogRecordIdComponent.
module CatalogRecordIdFormConcern
  extend ActiveSupport::Concern

  included do
    include CocinaModels::CatalogRecordIdConcern

    # The title retrieved from the catalog, shown read only to confirm the catalog record id; never written to Cocina.
    # A form attribute so that it survives a submission that fails validation.
    attribute :retrieved_title, :string
  end
end
