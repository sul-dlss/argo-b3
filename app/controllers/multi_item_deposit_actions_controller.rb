# frozen_string_literal: true

# Controller for Multi-Item Deposits.
class MultiItemDepositActionsController < ApplicationController
  def edit
    @multi_item_deposit_action = MultiItemDepositAction.find(params.expect(:id))
    authorize! @multi_item_deposit_action
  end

  # Create is a POST (rather than a GET new) so that prefetching or reloading does not create a deposit.
  def create
    authorize! with: ItemPolicy, to: :new?

    multi_item_deposit_action = MultiItemDepositAction.create!(user: current_user)
    redirect_to edit_multi_item_deposit_action_path(multi_item_deposit_action)
  end
end
