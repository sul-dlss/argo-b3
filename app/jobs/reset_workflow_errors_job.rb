# frozen_string_literal: true

# Job to reset workflow errors for a set of druids based on a search form.
class ResetWorkflowErrorsJob < ApplicationJob
  # @param effective_groups [Array<String>] the requesting user's authorization workgroups. This is
  #   a snapshot taken at enqueue time, so it preserves the requesting user's impersonation context
  #   even if their workgroups change before the job runs.
  def perform(search_form:, workflow_name:, process_name:, effective_groups:)
    user_scope = Permissions::UserScope.new(groups: effective_groups)
    druids = druids_for(search_form:, workflow_name:, process_name:, user_scope:)
    Rails.logger.info "Resetting workflow errors for #{workflow_name} - #{process_name} " \
                      "limited by #{search_form}: #{druids.join(', ')}"

    druids.each do |druid|
      Dor::Services::Client.object(druid).workflow(workflow_name).process(process_name)
                           .update(status: 'waiting', current_status: 'error')
    end
  end

  private

  def druids_for(search_form:, workflow_name:, process_name:, user_scope:)
    Searchers::DruidList.call(
      search_form: search_form.with(wps_workflows: [[workflow_name, process_name, 'error'].join(':')]),
      user_scope:
    )
  end
end
