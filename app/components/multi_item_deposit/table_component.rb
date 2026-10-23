# frozen_string_literal: true

module MultiItemDeposit
  # Component for rendering a table of Multi-Item Deposits
  class TableComponent < ApplicationComponent
    # @param show_user [Boolean] whether to include the user column, e.g., when listing the deposits of other users
    def initialize(multi_item_deposit_actions:, label:, id:, show_user: false, show_label: false)
      @multi_item_deposit_actions = multi_item_deposit_actions
      @label = label
      @id = id
      @show_user = show_user
      @show_label = show_label
      super()
    end

    attr_reader :multi_item_deposit_actions, :label, :id, :show_label

    def show_user? = @show_user

    def values_for(multi_item_deposit_action)
      values = [
        link_to(multi_item_deposit_action.name, multi_item_deposit_action_path(multi_item_deposit_action)),
        helpers.format_datetime(multi_item_deposit_action.created_at, format: :date_only),
        helpers.format_datetime(multi_item_deposit_action.initiating_deposit_completed_at, format: :date_only),
        MultiItemDepositAction::DISPLAY_STATUSES.fetch(multi_item_deposit_action.display_status),
        workflow_status_link_for(multi_item_deposit_action)
      ]
      values.insert(1, multi_item_deposit_action.user.sunetid) if show_user?
      values
    end

    def empty_message
      I18n.t('multi_item_deposit_actions.history.empty')
    end

    private

    # Without Item Deposits, the workflow grid would not be limited to any objects.
    def workflow_status_link_for(multi_item_deposit_action)
      return unless multi_item_deposit_action.item_deposit_actions.exists?

      link_to('Workflow status', workflow_grid_path(multi_item_deposit_action_ids: [multi_item_deposit_action.id]))
    end
  end
end
