# frozen_string_literal: true

# Policy for agreements.
class AgreementPolicy < ApplicationPolicy
  alias_rule :new?, to: :create?

  # Agreements are governed by the ur APO (Internal System Objects), so only users who can edit
  # that APO may register them.
  def create?
    permission_scope.edit_targets.include?(Settings.ur_apo_druid)
  end
end
