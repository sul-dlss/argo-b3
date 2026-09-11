# frozen_string_literal: true

# Job for validating a form asynchronously.
class ValidateFormJob < ApplicationJob
  def perform(form_validation_action:)
    form_validation_action.status_started!

    form = form_validation_action.form
    if form.valid?
      form_validation_action.mark_valid!(form)
    else
      form_validation_action.mark_invalid!(form)
    end
  rescue StandardError => e
    Honeybadger.notify(e,
                       context: { form_validation_action_id: form_validation_action.id,
                                  user: form_validation_action.user.sunetid })
    form_validation_action.status_failed!
  end
end
