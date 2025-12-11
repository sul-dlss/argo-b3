# frozen_string_literal: true

# Job to reset workflow errors for a set of druids based on a search form.
class ResetWorkflowErrorsJob < ApplicationJob
  def perform(search_form:, workflow_name:, process_name:)
    druids = druids_for(search_form:, workflow_name:, process_name:)
    Rails.logger.info "Resetting workflow errors for #{workflow_name} - #{process_name} " \
                      "limited by #{search_form}: #{druids.join(', ')}"

    druids.each do |druid|
      Dor::Services::Client.object(druid).workflow(workflow_name).process(process_name)
                           .update(status: 'waiting', current_status: 'error')
    end
  end

  private

  def druids_for(search_form:, workflow_name:, process_name:)
    search_form.wps_workflows << [workflow_name, process_name, 'error'].join(':')
    Searchers::DruidList.call(search_form:)
  end
end
