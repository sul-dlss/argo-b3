# frozen_string_literal: true

# This class is used to store the current variables (e.g., user) in a thread-safe way.
# This obviates the need to pass these variables around as arguments, e.g., to view components.
# They can be accessed with Current.user, etc.
#
# Attributes:
# - user [User, nil]: currently authenticated user.
# - effective_groups [Array<String>, nil]: authorization groups currently in effect for policy checks.
#   When impersonating, this is the impersonated workgroup list from cookie; otherwise nil.
# - impersonated_groups [Array<String>, nil]: selected workgroups being impersonated for this request.
class Current < ActiveSupport::CurrentAttributes
  attribute :user, :effective_groups, :impersonated_groups

  def impersonating?
    impersonated_groups.present?
  end
end
