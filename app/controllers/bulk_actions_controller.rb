# frozen_string_literal: true

# Controller for bulk actions.
class BulkActionsController < ApplicationController
  PER_PAGE = 20

  before_action :set_bulk_action, only: %i[destroy file show]
  skip_verify_authorized only: %i[index new]

  def index
    bulk_actions = Current.user.bulk_actions.order(created_at: :desc, id: :desc)
    @total_results = bulk_actions.count
    @page = [params[:page].to_i, 1].max
    @total_pages = (@total_results.to_f / PER_PAGE).ceil
    @bulk_actions = bulk_actions.limit(PER_PAGE).offset((@page - 1) * PER_PAGE)
  end

  def show
    authorize! @bulk_action
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
