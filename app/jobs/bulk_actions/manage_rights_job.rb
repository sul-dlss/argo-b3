# frozen_string_literal: true

module BulkActions
  # Job to update access
  class ManageRightsJob < DruidsJob
    def perform(bulk_action:, druids:, view:, download:, location:, **) # rubocop:disable Metrics/ParameterLists
      @view = view
      @download = download
      @location = location
      super
    end

    attr_reader :view, :download, :location

    # Update access rights
    class JobItem < BaseJobItem
      delegate :view, :download, :location, to: :job

      def perform
        return unless check_update_ability?

        return unless check_object_type?(allow_admin_policy: false)

        if cocina_object.collection?
          mutate_cocina_collection
        else
          mutate_cocina_dro
        end

        save_model_and_deposit!(description: 'Updated rights', success_message: 'Rights updated successfully')
      end

      private

      def mutate_cocina_collection
        # Collection only allows setting view access to dark or world
        cocina_model.access_view = (view == 'dark' ? 'dark' : 'world')
      end

      def mutate_cocina_dro
        cocina_model.access_view = view
        cocina_model.access_download = download
        cocina_model.access_location = location
      end
    end
  end
end
