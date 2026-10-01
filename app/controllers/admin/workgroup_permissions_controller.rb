# frozen_string_literal: true

module Admin
  # Controller for listing the permissions held by workgroups
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

    private

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
