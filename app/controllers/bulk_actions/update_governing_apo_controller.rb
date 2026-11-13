# frozen_string_literal: true

module BulkActions
  # Controller for update governing APO bulk action.
  class UpdateGoverningApoController < FormsController
    private

    # Moving an item requires edit permission on the new APO, which the job also checks.
    def set_form_options
      @apo_options = Searchers::AdminPolicyList.call(user_scope: current_user_scope, editable: true)
    end
  end
end
