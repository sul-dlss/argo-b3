# frozen_string_literal: true

# Helper for forms that disable actions while submitting (see disable_actions_controller.js)
module DisableActionsHelper
  # Data attributes for a form whose submission disables the enclosing disable-actions controller's targets
  # until the submission completes.
  def disable_actions_form_data
    { action: 'turbo:submit-start->disable-actions#disable turbo:submit-end->disable-actions#enable' }
  end
end
