# frozen_string_literal: true

module Admin
  # Form for adding a read restricted or edit permission for a workgroup to an APO or collection.
  class ObjectPermissionForm < ApplicationForm
    PERMISSION_TYPES = %w[read_restricted edit].freeze

    attribute :target_druid, :string
    attribute :workgroup, :string
    normalizes_whitespace :workgroup
    validates :workgroup, presence: true
    validate :permission_not_duplicated

    attribute :permission_type, :string, default: 'read_restricted'

    def self.immutable_attributes
      [:target_druid]
    end

    # @return [Permission] the created permission
    def save!
      Permission.create!(target_druid:, workgroup:, permission_type:)
    end

    # @return [Array<String>] the workgroups that have any permission, for selecting an existing workgroup,
    #   plus the entered workgroup so that a new workgroup is retained when the form is re-rendered with errors
    def workgroup_options
      (Permission.distinct.pluck(:workgroup) + [workgroup]).compact.uniq.sort
    end

    private

    def permission_not_duplicated
      return unless Permission.exists?(target_druid:, workgroup:, permission_type:)

      errors.add(:workgroup, I18n.t('errors.object_permission.duplicate'))
    end
  end
end
