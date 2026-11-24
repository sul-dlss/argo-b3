# frozen_string_literal: true

# Form for replacing the administrative tags of an existing object.
class AdministrativeTagsForm < ApplicationForm
  include TagsFormConcern

  attribute :tags, default: -> { [] }

  # @param [Array<String>] tags the object's current tags
  # @return [AdministrativeTagsForm] a form with the tags split into other, project, and ticket tags
  def self.from_tags(tags)
    new(TagsFormConcern.tag_fields_attributes(tags))
  end

  # Tags are populated by validation, so call these after a successful validation.
  # @param [Array<String>] current_tags the object's current tags
  # Order is ignored since DSA returns tags in insertion order, not form order.
  def tags_changed?(current_tags)
    tags.sort != current_tags.sort
  end

  # @param [String] druid
  # @raise [Sdr::AdministrativeTags::Error] if there is an error replacing the tags
  def save!(druid:)
    Sdr::AdministrativeTags.replace(druid:, tags:)
  end
end
