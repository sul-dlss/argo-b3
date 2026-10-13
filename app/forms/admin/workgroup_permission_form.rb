# frozen_string_literal: true

module Admin
  # Form for toggling the read unrestricted permission for a workgroup.
  class WorkgroupPermissionForm < ApplicationForm
    attribute :workgroup, :string
    attribute :read_unrestricted, :boolean, default: false

    def self.immutable_attributes
      [:workgroup]
    end
  end
end
