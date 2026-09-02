# frozen_string_literal: true

# Policy for digital objects.
class ObjectPolicy < ApplicationPolicy
  alias_rule :show_json?, to: :show?
  alias_rule :update?, to: :edit?

  def show?
    true
  end

  # Edit permission is granted when a user is in a workgroup with edit
  # permissions that target the object itself, one of its collections, or its
  # APO.
  def edit?
    Permission.permission_type_edit.exists?(
      workgroup: user.groups,
      target_druid: edit_target_druids
    )
  end

  private

  def edit_target_druids
    [record_druid, *record_collection_druids, record_admin_policy_druid].compact.uniq
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
