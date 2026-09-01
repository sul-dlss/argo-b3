# frozen_string_literal: true

# Controller for admin-related actions
class AdminController < ApplicationController
  def groups
    authorize! :groups?, with: AdminPolicy
  end

  def impersonate
    authorize! :impersonate?, with: AdminPolicy
    available_workgroups = Impersonation::Workgroups.available_for_user(user: current_user)

    @selected_workgroups = Current.impersonated_groups || []
    @workgroup_columns = available_workgroups.each_slice(workgroups_per_column).to_a
  end

  def update_impersonation
    authorize! :impersonate?, with: AdminPolicy
    selected_workgroups = params.fetch(:impersonation, {}).fetch(:workgroups, [])
    available_workgroups = Impersonation::Workgroups.available_for_user(user: current_user)
    impersonated_workgroups = Array(selected_workgroups) & available_workgroups

    Impersonation::Workgroups.update_cookie(cookies:, groups: impersonated_workgroups)

    redirect_to admin_impersonate_path
  end

  def stop_impersonating
    authorize! :stop_impersonating?, with: AdminPolicy
    Impersonation::Workgroups.clear_cookie(cookies:)

    redirect_to admin_impersonate_path
  end

  private

  def workgroups_per_column
    12
  end
end
