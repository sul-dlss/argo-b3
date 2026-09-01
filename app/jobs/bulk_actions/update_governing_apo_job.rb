# frozen_string_literal: true

module BulkActions
  # Job to move objects to a new governing APO
  class UpdateGoverningApoJob < ClosingDruidsJob
    def perform(bulk_action:, druids:, close_version:, new_apo_id:)
      @new_apo_id = new_apo_id
      super
    end

    attr_reader :new_apo_id

    # Update governing APO on a single item
    class JobItem < BaseJobItem
      delegate :new_apo_id, to: :job

      def perform # rubocop:disable Metrics/AbcSize
        return failure!(message: "Not authorized to move item to #{new_apo_id}") unless can_update_governing_apo?
        return unless check_object_type?(allow_admin_policy: false)

        cocina_model.admin_policy_druid = new_apo_id

        return failure!(message: cocina_model.errors.full_messages.join(', ')) unless cocina_model.valid?
        return success!(message: 'No changes to governing APO') unless cocina_model.changed?

        open_new_version_if_needed!(description: 'Updated governing APO')
        cocina_model.save!(user_name: user_id, description: 'Updated governing APO')
        close_version_if_needed!

        success!(message: 'Successfully updated governing APO')
      end

      private

      # The user must have edit permission on both the APO currently governing the item and the new APO,
      # unless they are an admin (who can manage anything).
      def can_update_governing_apo?
        return true if admin?

        allowed_to?(:update?, cocina_object, with: ObjectPolicy, context: { user: }) &&
          Permission.permission_type_edit.exists?(workgroup: user.groups, target_druid: new_apo_id)
      end

      def admin?
        Permission.permission_type_admin.exists?(workgroup: user.groups)
      end
    end
  end
end
