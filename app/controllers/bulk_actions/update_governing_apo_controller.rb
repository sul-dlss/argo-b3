# frozen_string_literal: true

module BulkActions
  # Controller for update governing APO bulk action.
  class UpdateGoverningApoController < BulkActionApplicationController
    def new
      set_apo_options
      super
    end

    def create
      set_apo_options
      super
    end

    private

    def bulk_action_config
      BulkActions::UPDATE_GOVERNING_APO
    end

    def job_params
      {
        druids: druids_from_form,
        close_version: @bulk_action_form.close_version,
        new_apo_id: @bulk_action_form.new_apo_id
      }
    end

    def set_apo_options
      @apo_options = Searchers::AdminPolicyList.call
    end
  end
end
