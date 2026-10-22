# frozen_string_literal: true

module Admin
  # Controller for listing, adding, and deleting the read restricted and edit permissions for an APO or collection.
  class ObjectPermissionsController < ApplicationController
    MANAGEABLE_OBJECT_TYPES = %w[APO collection].freeze

    before_action :authorize_manage_permissions!
    before_action :set_druid
    before_action :set_solr_doc

    def index
      @object_permission_form = ObjectPermissionForm.new(target_druid: @druid)
      set_permissions
    end

    def create
      @object_permission_form = ObjectPermissionForm.new(object_permission_params)
      return render formats: :turbo_stream, status: :unprocessable_content unless @object_permission_form.valid?

      @object_permission_form.save!
      @object_permission_form = ObjectPermissionForm.new(target_druid: @druid)
      set_permissions
      flash.now[:toast] = t('admin.object_permissions.toasts.added')
      render formats: :turbo_stream
    end

    def destroy
      Permission.find_by!(id: params.expect(:id), target_druid: @druid,
                          permission_type: ObjectPermissionForm::PERMISSION_TYPES).destroy!

      set_permissions
      flash.now[:toast] = t('admin.object_permissions.toasts.deleted')
      render formats: :turbo_stream
    end

    private

    def authorize_manage_permissions!
      authorize! to: :manage_permissions?, with: AdminPolicy
    end

    def set_druid
      @druid = DruidSupport.prefixed_druid_from(params.expect(:object_druid)).tap do |druid|
        raise ActionController::RoutingError, 'Not Found' unless DruidValidator::PATTERN.match?(druid)
      end
    end

    # Permissions are only managed for APOs and collections.
    def set_solr_doc
      @solr_doc = SolrDocPresenter.new(solr_doc: Sdr::Repository.find_solr(druid: @druid))
      raise ActionController::RoutingError, 'Not Found' unless @solr_doc.object_type?(*MANAGEABLE_OBJECT_TYPES)
    end

    def set_permissions
      @permissions = Permission.where(target_druid: @druid, permission_type: ObjectPermissionForm::PERMISSION_TYPES)
                               .order(:workgroup, :permission_type)
    end

    def object_permission_params
      ObjectPermissionForm.params_from(params).merge(target_druid: @druid)
    end
  end
end
