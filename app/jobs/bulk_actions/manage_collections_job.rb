# frozen_string_literal: true

module BulkActions
  # Job to update the collections that objects are members of
  class ManageCollectionsJob < ClosingDruidsJob
    def perform(bulk_action:, druids:, close_version:, collection_druids:)
      @collection_druids = collection_druids
      super
    end

    attr_reader :collection_druids

    # Update collection membership on a single item
    class JobItem < BaseJobItem
      delegate :collection_druids, to: :job

      def perform # rubocop:disable Metrics/AbcSize
        return unless check_update_ability?
        return unless check_object_type?(allow_collection: false, allow_admin_policy: false)

        cocina_model.collection_druids = collection_druids

        return failure!(message: cocina_model.errors.full_messages.join(', ')) unless cocina_model.valid?
        return success!(message: 'No changes to collections') unless cocina_model.changed?

        open_new_version_if_needed!(description: 'Updated collection')
        cocina_model.save!(user_name: user_id, description: 'Updated collection')
        close_version_if_needed!

        success!(message: 'Collection updated')
      end
    end
  end
end
