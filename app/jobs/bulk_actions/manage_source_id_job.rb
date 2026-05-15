# frozen_string_literal: true

module BulkActions
  # Job to update source ids from a CSV file
  class ManageSourceIdJob < ClosingCsvJob
    # Update source id from single CSV row
    class JobItem < BaseCsvJobItem
      # Job to update source id from single CSV row
      def perform # rubocop:disable Metrics/AbcSize
        return unless check_update_ability?

        source_id = row['source_id']
        cocina_model.source_id = source_id

        return failure!(message: cocina_model.errors.full_messages.to_sentence) unless cocina_model.valid?
        return success!(message: 'No changes to source ID') unless cocina_model.changed?

        open_new_version_if_needed!(description: description_msg)
        cocina_model.save!(user_name: user_id, description: description_msg)
        close_version_if_needed!

        success!(message: 'Successfully updated')
      end

      private

      def description_msg
        'Updated source ID'
      end
    end
  end
end
