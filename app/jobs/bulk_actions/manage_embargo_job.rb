# frozen_string_literal: true

module BulkActions
  # Job to update/add embargoes to objects
  class ManageEmbargoJob < ClosingCsvJob
    # Update or create an embargo for a single CSV row
    class JobItem < BaseCsvJobItem
      def perform # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
        return unless check_update_ability?
        return unless check_object_type?(allow_collection: false, allow_admin_policy: false)
        return unless check_release_date?

        cocina_model.embargo_release_date = release_date
        cocina_model.embargo_view = row['view'].presence
        cocina_model.embargo_download = row['download'].presence
        cocina_model.embargo_location = row['location'].presence

        unless cocina_model.valid?
          failure!(message: cocina_model.errors.full_messages.join('; '))
          return
        end

        return success!(message: 'No changes made') unless cocina_model.changed?

        open_new_version_if_needed!(description: 'Created or updated embargo')
        cocina_model.save!(user_name: user_id, description: 'Created or updated embargo')
        close_version_if_needed!
        success!(message: 'Embargo updated')
      end

      private

      def check_release_date?
        if row['release_date'].blank?
          failure!(message: 'Missing required value for "release_date"')
          return false
        end

        release_date

        true
      rescue Date::Error
        failure!(message: "#{row['release_date']} is not a valid date")
        false
      end

      def release_date
        @release_date ||= DateTime.parse(row['release_date'])
      end
    end
  end
end
