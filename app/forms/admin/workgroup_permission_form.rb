# frozen_string_literal: true

module Admin
  # Form for toggling the read unrestricted permission for a workgroup.
  class WorkgroupPermissionForm < ApplicationForm
    attribute :read_unrestricted, :boolean, default: false
  end
end
