# frozen_string_literal: true

# Policy for registering multiple items (DROs)
class MultipleItemsPolicy < ApplicationPolicy
  # The record is the FormValidationAction for the submitted registration form.
  def show?
    record.user_id == user.id
  end
end
