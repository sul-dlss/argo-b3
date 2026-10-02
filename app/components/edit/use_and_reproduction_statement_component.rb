# frozen_string_literal: true

module Edit
  # Component for rendering edit form for use and reproduction statement
  class UseAndReproductionStatementComponent < ApplicationComponent
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
      @label_text || t('edit.items.fields.use_and_reproduction_statement.label')
    end

    def help_text
      t('edit.items.fields.use_and_reproduction_statement.help_text_html',
        url: Settings.links.use_and_reproduction_statement)
    end
  end
end
