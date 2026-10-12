# frozen_string_literal: true

module Admin
  # Form for toggling the read unrestricted permission for a workgroup.
  class WorkgroupPermissionForm < ApplicationForm
    attribute :workgroup, :string
    attribute :read_unrestricted, :boolean, default: false
    validates :workgroup, presence: true

    def self.immutable_attributes
      [:workgroup]
    end

    # @param [String] workgroup
    # @return [WorkgroupPermissionForm] a form reflecting the workgroup's current read unrestricted permission
    def self.for_workgroup(workgroup)
      new(workgroup:, read_unrestricted: read_unrestricted_permission_for(workgroup).present?)
    end

    def self.read_unrestricted_permission_for(workgroup)
      Permission.permission_type_read_unrestricted.find_by(workgroup:, target_druid: nil)
    end

    # When saving, ensures the workgroup has a read unrestricted permission when Yes is selected,
    # and removes it when No is selected.
    # @return [Boolean] true if saved, false if invalid
    def save # rubocop:disable Naming/PredicateMethod
      return false unless valid?

      if read_unrestricted
        Permission.create!(workgroup:, permission_type: :read_unrestricted) unless read_unrestricted_permission
      else
        # guard against nil, because there may only be specific target druid rows for
        # this workgroup still, with no specific row to delete for just read unrestricted
        read_unrestricted_permission&.destroy!
      end
      true
    end

    # @return [ActiveRecord::Relation<Permission>] the workgroup's specific permissions (i.e. target druids)
    def additional_permissions
      Permission.where(workgroup:).where.not(id: read_unrestricted_permission&.id).order(:permission_type)
    end

    private

    def read_unrestricted_permission
      return @read_unrestricted_permission if defined?(@read_unrestricted_permission)

      @read_unrestricted_permission = self.class.read_unrestricted_permission_for(workgroup)
    end
  end
end
