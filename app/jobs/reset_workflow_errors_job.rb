class ResetWorkflowErrorsJob < ApplicationJob
  def perform(search_form:, workflow:, step:)
    Rails.logger.info("Resetting workflow processes for workflow=#{workflow}, step=#{step} with search_form=#{search_form}")
    # Dor::Services::Client.object(druid).workflow(workflow).process(step).update(status: 'waiting', current_status: 'error')
  end
end
