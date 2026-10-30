# frozen_string_literal: true

# Helpers for system specs of forms that are validated asynchronously (FormValidationAction), e.g., registering
# multiple items.
module FormValidationHelpers
  # Waits for the validating page, which is shown while the form validation action is pending.
  # @return [FormValidationAction] the form validation action for the submitted form
  def wait_for_validating_page
    expect(page).to have_text('Validating...')

    FormValidationAction.last.tap do |form_validation_action|
      expect(page).to have_current_path(multiple_item_path(form_validation_action))
    end
  end

  RSpec.configure do |config|
    config.include FormValidationHelpers, type: :system
  end
end
