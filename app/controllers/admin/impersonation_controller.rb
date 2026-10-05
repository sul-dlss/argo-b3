# frozen_string_literal: true

module Admin
  # Controller for impersonating workgroups
  class ImpersonationController < ApplicationController
    WORKGROUPS_PER_COLUMN = 12

    def edit
      authorize! to: :impersonate?, with: AdminPolicy

      available_workgroups = Impersonation::Workgroups.available_for_user(user: current_user)

      @selected_workgroups = Current.impersonated_groups || []
      @workgroup_columns = available_workgroups.each_slice(WORKGROUPS_PER_COLUMN).to_a
    end

    def update
      authorize! to: :update_impersonation?, with: AdminPolicy

      if impersonated_workgroups.empty?
        flash[:warning] = I18n.t('admin.impersonation.invalid')
        redirect_to admin_impersonate_path
      else
        Impersonation::Workgroups.update_cookie(cookies:, groups: impersonated_workgroups)
        flash[:success] = I18n.t('admin.impersonation.start')
        redirect_to root_path
      end
    end

    def destroy
      authorize! to: :stop_impersonating?, with: AdminPolicy

      Impersonation::Workgroups.clear_cookie(cookies:)

      flash[:success] = I18n.t('admin.impersonation.stop')
      redirect_to root_path
    end

    private

    def impersonation_params
      params.permit(impersonation: { workgroups: [] })[:impersonation] || {}
    end

    def impersonated_workgroups
      selected_workgroups = impersonation_params[:workgroups] || []
      available_workgroups = Impersonation::Workgroups.available_for_user(user: current_user)
      Array(selected_workgroups) & available_workgroups
    end
  end
end
