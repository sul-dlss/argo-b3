# frozen_string_literal: true

# Concern for the tags of an object, which are entered as separate other, project, and ticket
# tags and combined into the single list of tags applied to the object.
#
# Tags can also be typed all at once in multiple_tags, separated by tabs or new lines. Each must be
# a valid tag; the project and ticket tags among them are combined with the project and ticket tags.
#
# Requires a tags attribute, as provided by CocinaModels::Base.
module TagsFormConcern
  extend ActiveSupport::Concern

  # Deliberately more lenient than the prefixes, so that a tag like "project : Argo" is saved as a
  # project tag rather than as an other tag.
  MULTIPLE_PROJECT_TAG_PATTERN = /\Aproject\s*:\s*/i
  MULTIPLE_TICKET_TAG_PATTERN = /\Aticket\s*:\s*/i

  included do
    has_many :other_tags
    has_many :project_tags
    has_many :ticket_tags
    attribute :multiple_tags, :string
    validate :multiple_tags_valid

    after_validation :populate_tags
  end

  # @param [Array<String>] tags an object's tags
  # @return [Hash] attributes that fill a form's other, project, and ticket tag fields with the tags
  def self.tag_fields_attributes(tags)
    project_tags, rest = tags.partition { |tag| tag.start_with?(ProjectTagForm::PROJECT_TAG_PREFIX) }
    ticket_tags, other_tags = rest.partition { |tag| tag.start_with?(TicketTagForm::TICKET_TAG_PREFIX) }
    { other_tags_attributes: other_tags.map { |tag| { tag: } },
      project_tags_attributes: project_tags.map { |tag| { tag: } },
      ticket_tags_attributes: ticket_tags.map { |tag| { tag: } } }
  end

  private

  # Translated when validating, since a symbol or proc message option won't survive FormErrorsSerializer.
  def multiple_tags_valid
    invalid_tags = multiple_tag_lines.grep_v(OtherTagForm::VALID_TAG_PATTERN)
    return if invalid_tags.empty?

    errors.add(:multiple_tags, :invalid,
               message: I18n.t('edit.items.fields.multiple_tags.invalid', tags: invalid_tags.join(', ')))
  end

  def populate_tags
    self.tags = (raw_other_tags + multiple_other_tags +
                 raw_project_tags + multiple_project_tags +
                 raw_ticket_tags + multiple_ticket_tags).compact_blank.uniq
  end

  def raw_other_tags
    other_tags.map(&:tag)
  end

  def raw_project_tags
    project_tags.filter_map do |project_tag|
      "#{ProjectTagForm::PROJECT_TAG_PREFIX}#{project_tag.tag}" if project_tag.tag.present?
    end
  end

  def raw_ticket_tags
    ticket_tags.filter_map do |ticket_tag|
      "#{TicketTagForm::TICKET_TAG_PREFIX}#{ticket_tag.tag}" if ticket_tag.tag.present?
    end
  end

  def multiple_tag_lines
    multiple_tags.to_s.split(/[\t\r\n]+/).map(&:strip).compact_blank
  end

  def valid_multiple_tags
    multiple_tag_lines.grep(OtherTagForm::VALID_TAG_PATTERN)
  end

  def multiple_other_tags
    valid_multiple_tags.grep_v(Regexp.union(MULTIPLE_PROJECT_TAG_PATTERN, MULTIPLE_TICKET_TAG_PATTERN))
  end

  def multiple_project_tags
    prefixed_multiple_tags(MULTIPLE_PROJECT_TAG_PATTERN, ProjectTagForm::PROJECT_TAG_PREFIX)
  end

  def multiple_ticket_tags
    prefixed_multiple_tags(MULTIPLE_TICKET_TAG_PATTERN, TicketTagForm::TICKET_TAG_PREFIX)
  end

  # Like the project and ticket tag forms, tolerates a tag that repeats the prefix (e.g., "Project : Project : Maps").
  def prefixed_multiple_tags(pattern, prefix)
    valid_multiple_tags.grep(pattern) do |tag|
      "#{prefix}#{tag.sub(pattern, '').delete_prefix(prefix).strip}"
    end
  end
end
