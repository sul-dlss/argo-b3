# frozen_string_literal: true

module Admin
  # Controller for impersonating workgroups
  class ImpersonationController < ApplicationController
    WORKGROUP_COLUMNS = 4

    def edit
      authorize! to: :impersonate?, with: AdminPolicy

      @selected_workgroups = Current.impersonated_groups || []
      @workgroup_columns = workgroups.each_slice(workgroups.size.fdiv(WORKGROUP_COLUMNS).ceil).to_a
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
      Array(selected_workgroups) & workgroups
    end

    def workgroups
      Impersonation::Workgroups::WORKGROUPS
    end
  end
end
