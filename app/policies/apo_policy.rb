# frozen_string_literal: true

# Policy for APOs.
class ApoPolicy < ApplicationPolicy
  alias_rule :new?, to: :create?

  def create?
    # Only admins can create APOs.
    false
  end
end
