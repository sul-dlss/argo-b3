# frozen_string_literal: true

module BulkActions
  # Job to update source ids from a CSV file
  class ManageSourceIdJob < BaseCsvJob
    # Update source id from single CSV row
    class JobItem < BaseCsvJobItem
      # Job to update source id from single CSV row
      def perform
        return unless check_update_ability?

        cocina_model.source_id = row['source_id']

        save_model_and_deposit!(description: 'Updated source ID', success_message: 'Successfully updated',
                                unchanged_message: 'No changes to source ID')
      end
    end
  end
end
