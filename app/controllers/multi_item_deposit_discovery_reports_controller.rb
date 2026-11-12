# frozen_string_literal: true

# Controller for the report of the results of checking a Multi-Item Deposit's manifest (discovery).
class MultiItemDepositDiscoveryReportsController < ApplicationController
  before_action :set_multi_item_deposit_action

  def show
    authorize! @multi_item_deposit_action, to: :edit?

    # The page links to the report only once checking has completed, but a link in a stale tab may be followed
    # while checking is rerunning, when the report would be incomplete. The edit page then shows checking in progress.
    if @multi_item_deposit_action.discovery_completed_at.blank?
      return redirect_to edit_multi_item_deposit_action_path(@multi_item_deposit_action)
    end

    send_data DiscoveryReportCsv::Export.as_csv(multi_item_deposit_action: @multi_item_deposit_action),
              type: 'text/csv', filename: "multi_item_deposit_#{@multi_item_deposit_action.id}_discovery_report.csv"
  end

  private

  def set_multi_item_deposit_action
    @multi_item_deposit_action = MultiItemDepositAction.find(params.expect(:multi_item_deposit_action_id))
  end
end
