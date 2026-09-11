# frozen_string_literal: true

module Admin
  # Renders the workgroup checklist used by the impersonation form.
  class ImpersonationWorkgroupsComponent < ApplicationComponent
    def initialize(form:, workgroup_columns:, selected_workgroups:)
      @form = form
      @workgroup_columns = workgroup_columns
      @selected_workgroups = selected_workgroups
      super()
    end

    attr_reader :form, :workgroup_columns, :selected_workgroups
  end
end
