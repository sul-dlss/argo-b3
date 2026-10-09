# frozen_string_literal: true

module Admin
  # Controller for listing and editing the permissions held by workgroups
  class WorkgroupPermissionsController < ApplicationController
    WorkgroupResult = Struct.new(:workgroup, :read_unrestricted, :permission_count) do
      def initialize(workgroup:, read_unrestricted: false, permission_count: 0)
        super
      end
    end

    def index
      authorize! to: :index?, with: PermissionPolicy

      @workgroup_results = workgroup_results
    end

    def edit
      authorize! to: :edit?, with: PermissionPolicy

      @workgroup = workgroup
      @workgroup_permission_form = WorkgroupPermissionForm.new(read_unrestricted: read_unrestricted_permission.present?)
      @other_permissions = other_permissions
      @object_docs_by_druid = object_docs_by_druid(@other_permissions)
    end

    def update
      authorize! to: :update?, with: PermissionPolicy

      @workgroup_permission_form = WorkgroupPermissionForm.new(
        params.expect(WorkgroupPermissionForm.model_name.param_key.to_sym => WorkgroupPermissionForm.permitted_params)
      )
      save_read_unrestricted_permission

      flash[:toast] = t('admin.workgroup_permissions.toasts.updated')
      redirect_to admin_workgroup_permissions_path
    end

    def destroy
      authorize! to: :destroy?, with: PermissionPolicy

      @permission = Permission.find(params.expect(:id))
      @permission.destroy!

      flash.now[:toast] = t('admin.workgroup_permissions.toasts.deleted')
      render formats: :turbo_stream
    end

    private

    def workgroup
      @workgroup ||= params[:workgroup]
    end

    def read_unrestricted_permission
      return @read_unrestricted_permission if defined?(@read_unrestricted_permission)

      @read_unrestricted_permission =
        Permission.permission_type_read_unrestricted.find_by(workgroup:, target_druid: nil)
    end

    def save_read_unrestricted_permission
      if @workgroup_permission_form.read_unrestricted
        Permission.create!(workgroup:, permission_type: :read_unrestricted) unless read_unrestricted_permission
      else
        read_unrestricted_permission&.destroy!
      end
    end

    def other_permissions
      Permission.where(workgroup:).where.not(id: read_unrestricted_permission&.id).order(:permission_type)
    end

    def object_docs_by_druid(permissions)
      target_druids = permissions.filter_map(&:target_druid).uniq
      return {} if target_druids.empty?

      Searchers::ItemByDruid.call(druids: target_druids, user_scope: current_user_scope,
                                  fields: [Search::Fields::ID, Search::Fields::TITLE, Search::Fields::OBJECT_TYPES])
                            .map { |doc| SolrDocPresenter.new(solr_doc: doc.solr_doc) }
                            .index_by(&:druid)
    end

    def workgroup_results
      {}.tap do |result_map|
        add_read_unrestricted_results(result_map)
        add_permission_count_results(result_map)
      end.values.sort_by(&:workgroup)
    end

    def add_read_unrestricted_results(result_map)
      Permission.where(permission_type: 'read_unrestricted').pluck(:workgroup).each do |workgroup|
        result_map[workgroup] = WorkgroupResult.new(workgroup:, read_unrestricted: true)
      end
    end

    def add_permission_count_results(result_map)
      Permission.where.not(target_druid: nil).group(:workgroup).count.each do |workgroup, count|
        result_map[workgroup] ||= WorkgroupResult.new(workgroup:)
        result_map[workgroup].permission_count = count
      end
    end
  end
end
