# frozen_string_literal: true

module Edit
  # Component for rendering edit forms for the tags of an object (other, project, and ticket tags)
  # The form's object must include TagsFormConcern.
  class TagsComponent < ApplicationComponent
    def initialize(form:)
      @form = form
      super()
    end

    attr_reader :form

    def individual_tags_label
      t('edit.items.fields.individual_tags.label')
    end

    def other_tag_label
      t('edit.items.fields.other_tag.label').pluralize
    end

    def project_tag_label
      t('edit.items.fields.project_tag.label').pluralize
    end

    def ticket_tag_label
      t('edit.items.fields.ticket_tag.label').pluralize
    end
  end
end
