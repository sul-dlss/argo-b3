# frozen_string_literal: true

# Concern for forms that are validated asynchronously (see FormValidationAction and ValidateFormJob).
#
# The errors of such a form are applied by FormErrorsSerializer rather than by validating, so the form must
# refuse to be validated again. Include in a form that may be validated asynchronously, as well as in any of
# its nested forms, since FormErrorsSerializer applies errors to those too.
module PrevalidationConcern
  extend ActiveSupport::Concern

  # Raised when validating a form whose errors were applied by FormErrorsSerializer. Validating would clear those
  # errors and re-run the (potentially expensive) validations that were already performed asynchronously.
  class AlreadyValidatedError < StandardError; end

  # Marks the form as having had its errors applied by FormErrorsSerializer rather than by validating.
  # @return [void]
  def prevalidated!
    @prevalidated = true
  end

  # @return [Boolean] whether the form's errors were applied by FormErrorsSerializer
  def prevalidated?
    @prevalidated.present?
  end

  # @raise [AlreadyValidatedError] if the form is prevalidated
  def valid?(context = nil)
    if prevalidated?
      raise AlreadyValidatedError,
            "#{self.class} was already validated; validating would discard its errors"
    end

    super
  end
end
