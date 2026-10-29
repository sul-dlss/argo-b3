# frozen_string_literal: true

# Controller for the Globus directory that a Multi-Item Deposit's files are transferred to.
class MultiItemDepositGlobusController < ApplicationController
  before_action :set_multi_item_deposit_action

  def new
    authorize! @multi_item_deposit_action, to: :edit?

    render layout: false
  end

  # Creates the Globus directory for the Multi-Item Deposit.
  def create
    authorize! @multi_item_deposit_action, to: :edit?

    if @multi_item_deposit_action.create_globus_directory!
      redirect_to new_multi_item_deposit_action_globus_path(@multi_item_deposit_action)
    else
      @error = t('edit.contents.globus.errors.create_failed')
      render :new, layout: false, status: :unprocessable_content
    end
  end

  private

  def set_multi_item_deposit_action
    @multi_item_deposit_action = MultiItemDepositAction.find(params.expect(:multi_item_deposit_action_id))
  end
end
