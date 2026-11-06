# frozen_string_literal: true

# Controller for retrying, skipping, or completing a workflow process in error.
# Only the workflows frame is reloaded on success, since refreshing the whole object page is slow.
class WorkflowProcessesController < ApplicationController
  RULES = { 'waiting' => :retry_process?, 'skipped' => :skip_process?, 'completed' => :complete_process? }.freeze

  before_action :set_solr_doc

  def update
    authorize! @solr_doc, to: RULES.fetch(status), with: ObjectPolicy

    update_process
    flash.now[:toast] = t("workflow_processes.toasts.#{status}")
    render :updated, formats: :turbo_stream
  rescue Dor::Services::Client::ConflictResponse
    redirect_with_danger(t('workflow_processes.errors.conflict'))
  rescue Dor::Services::Client::Error => e
    redirect_with_danger(t('workflow_processes.errors.update_failed', message: e.message))
  end

  private

  def update_process
    Sdr::WorkflowService.update_process(druid:, workflow_name: params[:workflow_name], process: params[:process],
                                        version: params.expect(:version), status:, sunetid: current_user.sunetid)
    # The show page's cached solr doc is keyed on the lock, which process changes do not change.
    Rails.cache.delete(CacheSupport.solr_doc_cache_key(druid:))
  end

  def redirect_with_danger(message)
    flash[:danger] = message
    redirect_to object_path(druid:), status: :see_other
  end

  def set_solr_doc
    @solr_doc = SolrDocPresenter.new(solr_doc: Sdr::Repository.find_solr(druid:))
  end

  def druid
    params[:druid]
  end

  def status
    params.expect(:status)
  end
end
