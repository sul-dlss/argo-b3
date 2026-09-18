# frozen_string_literal: true

module CocinaModels
  # Presenter for an AdminPolicy cocina model.
  # It will delegate to the AdminPolicy model.
  # Initialize with: CocinaModels::AdminPolicyPresenter.new(admin_policy),
  # where admin_policy is a CocinaModels::AdminPolicy.
  class AdminPolicyPresenter < BasePresenter
    def display_access_rights
      "View: #{humanize_access_value(access_view)}"
    end
  end
end
