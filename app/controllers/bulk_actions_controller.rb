# frozen_string_literal: true

# Controller for bulk actions.
class BulkActionsController < ApplicationController
  PER_PAGE = 20

  before_action :set_bulk_action, only: %i[file show]
  skip_verify_authorized only: %i[index new]

  def index
    @bulk_actions = Current.user.bulk_actions.order(created_at: :desc, id: :desc).page(params[:page]).per(PER_PAGE)
  end

  def show
    authorize! @bulk_action
  end

  def new; end

  def file
    authorize! @bulk_action
    return head :not_found unless @bulk_action.downloadable_filename?(params[:filename])

    send_file(@bulk_action.filepath_for(filename: params[:filename]))
  end

  private

  def set_bulk_action
    @bulk_action = BulkAction.find(params[:id])
  end
end
