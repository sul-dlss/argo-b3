# frozen_string_literal: true

module Admin
  # Controller for listing, adding, and deleting the read restricted and edit permissions for an APO or collection.
  # Adding and deleting redirect back to the list, which the page morphs into place.
  class ObjectPermissionsController < ApplicationController
    before_action :set_druid
    before_action :set_solr_doc

    def index
      authorize! to: :manage_permissions?, with: AdminPolicy

      @object_permission_form = ObjectPermissionForm.new(target_druid: @druid)
      set_permissions
    end

    def create
      authorize! to: :manage_permissions?, with: AdminPolicy

      @object_permission_form = ObjectPermissionForm.new(object_permission_params)
      if @object_permission_form.valid?
        @object_permission_form.save!
        redirect_to_index(toast: t('admin.object_permissions.toasts.added'))
      else
        set_permissions
        render :index, status: :unprocessable_content
      end
    end

    def destroy
      authorize! to: :manage_permissions?, with: AdminPolicy

      Permission.find_by!(id: params.expect(:id), target_druid: @druid,
                          permission_type: ObjectPermissionForm::PERMISSION_TYPES).destroy!
      redirect_to_index(toast: t('admin.object_permissions.toasts.deleted'))
    end

    private

    def set_druid
      @druid = params.expect(:object_druid)
    end

    def set_solr_doc
      @solr_doc = SolrDocPresenter.new(solr_doc: Sdr::Repository.find_solr(druid: @druid))
    end

    def set_permissions
      @permissions = Permission.where(target_druid: @druid, permission_type: ObjectPermissionForm::PERMISSION_TYPES)
                               .order(:workgroup, :permission_type)
    end

    def object_permission_params
      ObjectPermissionForm.params_from(params).merge(target_druid: @druid)
    end

    def redirect_to_index(toast:)
      redirect_to admin_object_permissions_path(@druid), flash: { toast: }, status: :see_other
    end
  end
end
