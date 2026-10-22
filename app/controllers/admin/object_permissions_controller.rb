# frozen_string_literal: true

module Admin
  # Manages permissions scoped to an APO or collection.
  class ObjectPermissionsController < ApplicationController
    include ToastAndRefreshConcern

    TARGET_DRUID_PATTERN = /\A#{DruidValidator::PATTERN}\z/

    before_action :authorize_target

    # @return [void]
    def index
      @object_permission_form = ObjectPermissionForm.new
      set_page
    end

    # @return [void]
    def create
      @object_permission_form = ObjectPermissionForm.new(ObjectPermissionForm.params_from(params))
      if @object_permission_form.save(target_druid: @druid)
        permission_added
      else
        set_page
        render :index, formats: :html, status: :unprocessable_content
      end
    end

    # @return [void]
    def destroy
      object_permissions.find(params.expect(:id)).destroy!
      toast_and_refresh(t('admin.object_permissions.toasts.deleted'),
                        fallback_location: admin_object_permissions_path(@druid))
    end

    private

    # @return [void]
    def permission_added
      @object_permission_form = ObjectPermissionForm.new
      set_page
      respond_to do |format|
        format.turbo_stream
        format.html do
          flash[:toast] = t('admin.object_permissions.toasts.added')
          redirect_to admin_object_permissions_path(@druid), status: :see_other
        end
      end
    end

    # @return [void]
    def authorize_target
      authorize! to: :edit?, with: PermissionPolicy
      @druid = DruidSupport.prefixed_druid_from(params.expect(:object_id))
      raise ActionController::RoutingError, 'Not Found' unless TARGET_DRUID_PATTERN.match?(@druid)

      cocina_object = Sdr::Repository.find(druid: @druid)
      # Admin policy prechecks bypass rules, so the target type must be checked separately.
      head :not_found unless cocina_object.admin_policy? || cocina_object.collection?
    end

    # @return [void]
    def set_page
      @workgroups = Permission.distinct.order(:workgroup).pluck(:workgroup)
      @permissions = object_permissions.order(:workgroup, :permission_type)
    end

    # @return [ActiveRecord::Relation<Permission>] manageable permissions belonging to this object
    def object_permissions
      Permission.where(target_druid: @druid, permission_type: %w[read_restricted edit])
    end
  end
end
