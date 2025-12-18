# frozen_string_literal: true

# Controller for bulk actions.
class BulkActionsController < ApplicationController
  before_action :set_bulk_action, only: %i[destroy file]
  skip_verify_authorized only: %i[index new]

  def index
    @bulk_actions = Current.user.bulk_actions.order(created_at: :desc)
  end

  def new; end

  def destroy
    authorize! @bulk_action

    @bulk_action.destroy
    flash[:toast] = "#{@bulk_action.label} deleted"
    redirect_to bulk_actions_path
  end

  def file
    authorize! @bulk_action

    send_file(@bulk_action.filepath_for(filename: params[:filename]))
  end

  private

  def set_bulk_action
    @bulk_action = BulkAction.find(params[:id])
  end
end
