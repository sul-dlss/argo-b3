# frozen_string_literal: true

# Repository for interacting with the catalog (Folio, the Stanford Libraries ILS).
class CatalogRepository
  # Raised when the catalog cannot answer the question, e.g., Folio is unavailable.
  class Error < StandardError; end

  # Checks whether a catalog record exists for the given catalog record id (HRID).
  #
  # A catalog record id that matches multiple records is treated as not found, since it cannot
  # be used to unambiguously identify a single catalog record.
  #
  # @param catalog_record_id [String] the catalog record id (Folio HRID, e.g., "a12345")
  # @param allow_catalog_errors [Boolean] when true, treat a catalog error as if the record exists.
  #   This is intended for environments where Folio is not available (and so would otherwise block
  #   the caller); in production, leave this false so that catalog errors surface instead of
  #   allowing an operation to proceed against an unverified catalog record id.
  # @return [Boolean] true if a single matching catalog record exists (or if the catalog errored and
  #   allow_catalog_errors is true), false if no matching or multiple matching records were found
  # @raise [CatalogRepository::Error] if the catalog request fails and allow_catalog_errors is false
  def self.exists?(catalog_record_id:, allow_catalog_errors: false)
    FolioClient.fetch_instance_info(hrid: catalog_record_id)
    true
  rescue FolioClient::ResourceNotFound, FolioClient::MultipleResourcesFound
    false
  rescue FolioClient::Error => e
    raise Error, e.message unless allow_catalog_errors

    true
  end
end
