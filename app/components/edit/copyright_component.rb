# frozen_string_literal: true

module Edit
  # Component for rendering edit form for copyright
  class CopyrightComponent < ApplicationComponent
    INPUT_ROWS = 3

    def initialize(form:, container_classes: [], label_text: nil)
      @form = form
      @container_classes = container_classes
      @label_text = label_text
      super()
    end

    attr_reader :form

    def container_classes
      merge_classes(@container_classes)
    end

    def label_text
      @label_text || t('edit.items.fields.copyright.label')
    end

    def help_text
      t('edit.items.fields.copyright.help_text_html', url: Settings.links.copyright)
    end
  end
end
