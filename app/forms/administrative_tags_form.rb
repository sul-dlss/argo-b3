# frozen_string_literal: true

# Form for replacing the administrative tags of an existing object.
class AdministrativeTagsForm < ApplicationForm
  include TagsFormConcern

  attribute :tags, default: -> { [] }

  # @param [Array<String>] tags the object's current tags
  # @return [AdministrativeTagsForm] a form with the tags split into other, project, and ticket tags
  def self.from_tags(tags)
    project_tags, rest = tags.partition { |tag| tag.start_with?(ProjectTagForm::PROJECT_TAG_PREFIX) }
    ticket_tags, other_tags = rest.partition { |tag| tag.start_with?(TicketTagForm::TICKET_TAG_PREFIX) }
    new(other_tags_attributes: tag_attributes(other_tags),
        project_tags_attributes: tag_attributes(project_tags),
        ticket_tags_attributes: tag_attributes(ticket_tags))
  end

  def self.tag_attributes(tags)
    tags.map { |tag| { tag: } }
  end
  private_class_method :tag_attributes

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
