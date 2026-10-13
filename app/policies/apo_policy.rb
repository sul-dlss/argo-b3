# frozen_string_literal: true

# Policy for APOs.
class ApoPolicy < ApplicationPolicy
  alias_rule :new?, to: :create?

  # NOTE: Use ObjectPolicy for show?, edit?, and update? permissions.

  def create?
    # Only admins can create APOs.
    false
  end
end
