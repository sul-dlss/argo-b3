# frozen_string_literal: true

module BulkActions
  # Job to import structural metadata from a CSV file (roughly equivalent to Argo's ImportStructuralJob).
  # Unlike other CSV jobs, an object may have multiple rows, so the job is performed per druid rather than per row.
  class ImportStructuralMetadataJob < ClosingCsvJob
    def perform_bulk_action
      # Check that the druid column is present (check_druid_column?).
      # Check that StructuralCsv::Validator::REQUIRED_COLUMNS are present. If any are missing, log
      # "Missing required column \"<name>\"" for each and fail every druid (as check_druid_column? does).
      #
      # Pair each row with its spreadsheet row number (starting with 2).
      # A row with a blank druid is logged as its own failure (with its row number as index).
      # Group the remaining (row_number, row) pairs by druid, preserving the order in which each druid first appears.
      # For each druid, perform a JobItem with rows:, using the druid's first row number as index.
      # Rescue errors as BaseCsvJob#perform_bulk_action does.
    end

    def druid_count
      # The number of distinct druids.
    end

    # Import structural metadata from the rows for a single object
    class JobItem < BaseCsvJobItem
      def perform
        # return unless check_update_ability?
        #
        # If a mutable Content exists for the druid at the cocina object's lock (e.g., left by the Contents edit page):
        #   If it is staging or discovering, failure! (a StageFilesJob will update the object).
        #   Otherwise destroy! it (the import will make it stale anyway). Necessary since there is a unique index on
        #   druid, lock, and immutable.
        #
        # Build a fresh Content: Contents::Builder.call(cocina_object:, immutable: false)
        #
        # Result = StructuralCsv::Import.new(rows:, content:).call
        # If failure, failure! with each ValidationError as "Row N: reason", joined with "; ".
        #
        # Contents::ExternalIdentifierMinter.call(content:) (new file sets have no external identifier, which
        # StructuralMutator requires).
        #
        # Updated cocina object = CocinaObjectMutators::StructuralMutator.call(cocina_object:, content:)
        # If the updated structural equals the existing structural, success!('Structure unchanged') without
        # opening a version.
        #
        # open_new_version_if_needed!(description: 'Updated structural metadata')
        # Sdr::Repository.update(cocina_object:, user_name: user_id, description: 'Updated structural metadata')
        # close_version_if_needed!
        # success!(message: 'Updated structural metadata')
        #
        # ensure
        #   Destroy the Content built by this job (if any).
      end
    end
  end
end
