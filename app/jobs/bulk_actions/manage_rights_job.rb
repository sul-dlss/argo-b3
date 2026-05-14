# frozen_string_literal: true

module BulkActions
  # Job to update access
  class ManageRightsJob < ClosingDruidsJob
    def perform(bulk_action:, druids:, # rubocop:disable Metrics/ParameterLists
                view:, download:, location:, close_version: false)
      @view = view
      @download = download
      @location = location
      super
    end

    attr_reader :view, :download, :location

    # Update access rights
    class JobItem < BaseJobItem
      delegate :view, :download, :location, to: :job

      def perform # rubocop:disable Metrics/AbcSize
        return unless check_update_ability?

        unless cocina_object.dro? || cocina_object.collection?
          return failure!(message: "Not an item or collection (#{cocina_object.type})")
        end

        if cocina_object.collection?
          mutate_cocina_collection
        else
          mutate_cocina_dro
        end

        return success!(message: 'No changes made') unless cocina_model.changed?

        open_new_version_if_needed!(description: description_msg)
        cocina_model.save!(user_name: user, description: description_msg)
        close_version_if_needed!

        success!(message: 'Rights updated successfully')
      end

      private

      def description_msg
        'Updated rights'
      end

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
