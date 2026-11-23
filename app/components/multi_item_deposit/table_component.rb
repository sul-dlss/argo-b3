# frozen_string_literal: true

module MultiItemDeposit
  # Component for rendering a table of Multi-Item Deposits
  class TableComponent < ApplicationComponent
    def initialize(multi_item_deposit_actions:, label:, id:, show_label: false)
      @multi_item_deposit_actions = multi_item_deposit_actions
      @label = label
      @id = id
      @show_label = show_label
      super()
    end

    attr_reader :multi_item_deposit_actions, :label, :id, :show_label

    def values_for(multi_item_deposit_action)
      [
        # The description has its own column, so the link omits it (unlike MultiItemDepositAction#name).
        link_to("Multi-item deposit #{multi_item_deposit_action.id}",
                multi_item_deposit_action_path(multi_item_deposit_action)),
        multi_item_deposit_action.description,
        helpers.format_datetime(multi_item_deposit_action.created_at, format: :date_only),
        helpers.format_datetime(multi_item_deposit_action.initiating_deposit_completed_at, format: :date_only),
        MultiItemDepositAction::DISPLAY_STATUSES.fetch(multi_item_deposit_action.display_status),
        workflow_status_link_for(multi_item_deposit_action)
      ]
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
