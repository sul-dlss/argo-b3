# frozen_string_literal: true

# Concern for the tags of an object, which are entered as separate other, project, and ticket
# tags and combined into the single list of tags applied at registration.
#
# Requires a tags attribute, as provided by CocinaModels::Base.
module TagsFormConcern
  extend ActiveSupport::Concern

  included do
    has_many :other_tags
    has_many :project_tags
    has_many :ticket_tags
    # only used for text entry; text is parsed and added to the tag fields above
    attribute :multiple_tags, :string

    after_validation :populate_tags
  end

  private

  def populate_tags
    self.tags = (raw_other_tags + raw_project_tags + raw_ticket_tags).compact_blank.uniq
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
end
