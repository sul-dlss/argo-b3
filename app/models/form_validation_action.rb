# frozen_string_literal: true

# Model for tracking asynchronous form validations
class FormValidationAction < ApplicationRecord
  belongs_to :user

  enum :status,
       { created: 'created', queued: 'queued', started: 'started', valid: 'valid', invalid: 'invalid',
         failed: 'failed' },
       prefix: true

  validates :form_payload, presence: true

  # Note that when the form validation action is invalid, the returned form has its errors applied and so cannot
  # be validated again (see PrevalidationConcern::AlreadyValidatedError).
  # @return [ApplicationForm] the form, deserialized from the form payload
  def form
    form = FormSerializer.deserialize(form_payload)
    return form if error_data.blank?

    FormErrorsSerializer.deserialize(form:, error_data:)
  end

  # @param form [ApplicationForm] the form to serialize into the form payload
  # @raise [ArgumentError] if the form cannot be serialized by FormSerializer
  def form=(form)
    raise ArgumentError, "#{form.class} cannot be serialized by FormSerializer" unless FormSerializer.serialize?(form)

    self.form_payload = FormSerializer.serialize(form)
  end

  # Records that the form was validated and is valid.
  # The form payload is rewritten because validating may mutate the form (e.g. via before_validation callbacks),
  # so the payload reflects the form as validated rather than as submitted.
  # @param form [ApplicationForm] the validated form
  def mark_valid!(form)
    update!(status: 'valid', form_payload: FormSerializer.serialize(form), error_data: nil)
  end

  # Records that the form was validated and is invalid, along with its errors.
  # The form payload is rewritten because validating may mutate the form (e.g. via before_validation callbacks),
  # so the error data refers to the form as validated rather than as submitted.
  # @param form [ApplicationForm] the validated form
  def mark_invalid!(form)
    update!(status: 'invalid',
            form_payload: FormSerializer.serialize(form),
            error_data: FormErrorsSerializer.serialize(form))
  end
end
