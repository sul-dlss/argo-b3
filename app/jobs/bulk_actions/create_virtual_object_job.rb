# frozen_string_literal: true

module BulkActions
  # Job to create virtual objects from a CSV file (roughly equivalent to Argo's CreateVirtualObjectsJob).
  # Unlike other CSV jobs, the CSV has no header row: each row is a virtual object druid followed by its constituent
  # druids (in order).
  class CreateVirtualObjectJob < BaseCsvJob
    def csv
      @csv ||= CSV.parse(@csv_file)
    end

    private

    # Virtual object CSVs have no header row, so the first row is a data row.
    def first_row_number
      1
    end

    # The druid for the virtual object is always the first column.
    def druid_for(row)
      row.first
    end

    # There is no druid column, since there is no header row.
    def check_druid_column?
      true
    end

    # Create a single virtual object from a CSV row
    class JobItem < BaseCsvJobItem
      # Since DSA publishes each constituent, a virtual object with many constituents may take a while.
      TIMEOUT_IN_SECONDS = 15.minutes.to_i

      def perform
        return unless check_update_ability? && check_object_type?(allow_collection: false, allow_admin_policy: false)
        # DSA closes the version of the virtual object, which would deposit any draft changes.
        if Sdr::VersionService.open?(druid:)
          return failure!(message: 'Version is open; deposit or discard the draft first')
        end

        errors = create_virtual_object
        return failure!(message: errors.join('; ')) if errors.any?

        success!(message: 'Created virtual object')
      end

      private

      def constituent_druids
        row.drop(1)
      end

      # @return [Array<String>] the errors (empty if successful)
      def create_virtual_object
        url = Dor::Services::Client.virtual_objects.create(
          virtual_objects: [{ virtual_object_id: druid, constituent_ids: constituent_druids }]
        )
        result = Dor::Services::Client::AsyncResult.new(url:)
        return [] if result.wait_until_complete(timeout_in_seconds: TIMEOUT_IN_SECONDS)

        # DSA reports errors keyed by virtual object druid, while a timeout is reported as a string.
        result.errors.flat_map do |error|
          error.is_a?(Hash) ? error.values.flatten : "#{error} (the virtual object may still be created)"
        end
      end
    end
  end
end
