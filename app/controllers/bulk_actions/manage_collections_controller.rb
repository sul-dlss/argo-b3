# frozen_string_literal: true

module BulkActions
  # Controller for update collections bulk action.
  class ManageCollectionsController < BulkActionApplicationController
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

    # refetch titles for any selected collection druids in the selector so we can rebuild form on a validation error
    def set_form_options
      @collection_options = []
      return if params['bulk_actions_manage_collections'].blank? # return if new submission

      collection_druids = expected_params['collection_druids'] # fetch any submitted druids and then get the titles
      collection_titles = Searchers::CollectionListByDruid.call(druids: collection_druids).to_h(&:reverse)
      @collection_options = collection_druids.map do |druid|
        [collection_titles[druid] || DruidSupport.bare_druid_from(druid), druid]
      end
    end
  end
end
