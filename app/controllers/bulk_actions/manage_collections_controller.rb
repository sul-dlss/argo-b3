# frozen_string_literal: true

module BulkActions
  # Controller for update collections bulk action.
  class ManageCollectionsController < BulkActionApplicationController
    def new
      super
      set_collection_options
    end

    def create
      super
      set_collection_options
    end

    private

    def bulk_action_config
      BulkActions::MANAGE_COLLECTIONS
    end

    def job_params
      {
        druids: druids_from_form,
        close_version: @bulk_action_form.close_version,
        collection_druids: @bulk_action_form.collection_druids
      }
    end

    # Only the selected collections are options, since other options are loaded as the user types.
    def set_collection_options
      druids = @bulk_action_form.collection_druids
      titles = Searchers::CollectionListByDruid.call(druids:).to_h(&:reverse)
      @collection_options = druids.map { |druid| [titles[druid] || DruidSupport.bare_druid_from(druid), druid] }
    end
  end
end
