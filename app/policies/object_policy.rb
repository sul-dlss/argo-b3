# frozen_string_literal: true

# Policy for digital objects.
class ObjectPolicy < ApplicationPolicy
  alias_rule :show_json?, to: :show?
  alias_rule :update?, to: :edit?

  # 1. If you can edit the object, you can read it
  # 2. If the object is restricted, only users with a matching restricted permission can read.
  # 3. If the object is not restricted, users with unrestricted permission can read.
  def show?
    return true if edit?
    return read_restricted? if record_read_restricted?

    read_unrestricted?
  end

  # Edit permission is granted when a user is in a workgroup with edit
  # permissions that target the object itself, one of its collections, or its
  # APO.
  def edit?
    permission_scope.edit_targets.intersect?(permission_target_druids)
  end

  private

  def permission_scope
    @permission_scope ||= Permissions::UserScope.new(groups: current_groups)
  end

  def permission_target_druids
    [record_druid, *record_collection_druids, record_admin_policy_druid].compact.uniq
  end

  def read_restricted?
    permission_scope.restricted_targets.intersect?(permission_target_druids)
  end

  def read_unrestricted?
    permission_scope.read_unrestricted?
  end

  def record_read_restricted?
    read_restricted_permissions.exists?
  end

  def read_restricted_permissions
    Permission.permission_type_read_restricted.where(
      target_druid: permission_target_druids
    )
  end

  def record_druid
    prefixed_druid(record.respond_to?(:externalIdentifier) ? record.externalIdentifier : record_druid_from_solr)
  end

  def record_collection_druids
    values = if record.respond_to?(:structural)
               record.structural&.isMemberOf
             elsif record.respond_to?(:collection_druids)
               record.collection_druids
             elsif record.respond_to?(:fetch)
               record.fetch(Search::Fields::COLLECTION_DRUIDS, nil)
             end

    Array(values).filter_map { |value| prefixed_druid(value) }
  end

  def record_admin_policy_druid
    value = if record.respond_to?(:administrative)
              record.administrative&.hasAdminPolicy
            elsif record.respond_to?(:apo_druid)
              record.apo_druid
            else
              record.fetch(Search::Fields::APO_DRUID, nil)
            end

    prefixed_druid(value)
  end

  def record_druid_from_solr
    return record.druid if record.respond_to?(:druid)

    record.fetch(Search::Fields::ID, nil)
  end

  def prefixed_druid(value)
    DruidSupport.prefixed_druid_from(Array(value).first)
  end
end
