# frozen_string_literal: true

module Edit
  # Component for rendering edit forms for the tags of an item (other, project, and ticket tags)
  class TagsComponent < ApplicationComponent
    # Marks the has_many sections that the multiple-tags Stimulus controller distributes tags into.
    # Outlet selectors are resolved against the whole document, so this keeps unrelated has_many
    # sections from the same page (occurs in multiple item registration) out of the outlet set.
    TAG_FIELDS_CLASS = 'tag-fields'

    def initialize(form:)
      @form = form
      super()
    end

    attr_reader :form

    def tag_fields_classes
      ['my-fieldset', TAG_FIELDS_CLASS]
    end

    def tag_fields_selector
      ".#{TAG_FIELDS_CLASS}"
    end

    def text_area_id
      form.field_id(:multiple_tags)
    end

    def help_text_id
      form.field_id(:multiple_tags, :help)
    end

    # Maps each has_many field name to the legend of the section it is rendered under, so that the
    # controller can announce where the tags went using the labels the user can see.
    def section_labels
      {
        other_tags: other_tag_label,
        project_tags: project_tag_label,
        ticket_tags: ticket_tag_label
      }
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
