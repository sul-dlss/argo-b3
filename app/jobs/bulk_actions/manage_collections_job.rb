# frozen_string_literal: true

module BulkActions
  # Job to update the collections that objects are members of
  class ManageCollectionsJob < DruidsJob
    def perform(bulk_action:, druids:, collection_druids:, **)
      @collection_druids = collection_druids
      super
    end

    attr_reader :collection_druids

    # Update collection membership on a single item
    class JobItem < BaseJobItem
      delegate :collection_druids, to: :job

      def perform
        return unless check_update_ability?
        return unless check_object_type?(allow_collection: false, allow_admin_policy: false)

        cocina_model.collection_druids = collection_druids
        unless allowed_to?(:add_to_collections?, cocina_model, with: ItemPolicy)
          return failure!(message: 'Not authorized to add to collections')
        end

        save_model_and_deposit!(description: 'Updated collection', success_message: 'Collection updated',
                                unchanged_message: 'No changes to collections')
      end
    end
  end
end
