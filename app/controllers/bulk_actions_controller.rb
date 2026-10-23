# frozen_string_literal: true

# Controller for bulk actions.
class BulkActionsController < ApplicationController
  include ToastAndRefreshConcern

  PER_PAGE = 20

  before_action :set_bulk_action, only: %i[file show destroy]
  skip_verify_authorized only: %i[index new]

  def index
    @filter_form = BulkActions::FilterForm.new(filter_form_params, user: Current.user,
                                                                   admin: allowed_to?(:admin?, nil, with: AdminPolicy))
    @bulk_actions = authorized_scope(BulkAction.all).filtered(**@filter_form.filters)
                                                    .includes(:user)
                                                    .order(created_at: :desc, id: :desc)
                                                    .page(params[:page]).per(PER_PAGE)
  end

  def show
    authorize! @bulk_action
  end

  def new; end

  def destroy
    authorize! @bulk_action

    # NOTE: this delete action is not linked in the UI unless the bulk action is complete,
    # so this is just an extra guard to be sure it can't be deleted unless complete
    return head :conflict unless @bulk_action.completed?

    @bulk_action.destroy!
    toast_and_refresh(t('bulk_actions.delete_success'), fallback_location: bulk_actions_path)
  end

  def file
    authorize! @bulk_action
    return head :not_found unless @bulk_action.downloadable_filename?(params[:filename])

    send_file(@bulk_action.filepath_for(filename: params[:filename]))
  end

  private

  def filter_form_params
    BulkActions::FilterForm.params_from(params)
  end

  def set_bulk_action
    @bulk_action = BulkAction.find(params[:id])
  end
end
