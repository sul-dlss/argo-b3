# frozen_string_literal: true

module Edit
  # Component for rendering edit form for use and reproduction statement
  # The form's object must have a use_and_reproduction_statement attribute.
  class UseAndReproductionStatementComponent < ApplicationComponent
    INPUT_ROWS = 3

    # @param apo_defaults [Boolean] true to show the selected APO's default use and reproduction statement, using the
    #   apo-defaults Stimulus controller
    def initialize(form:, container_classes: [], label_text: nil, apo_defaults: false)
      @form = form
      @container_classes = container_classes
      @label_text = label_text
      @apo_defaults = apo_defaults
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
      help_text = t('edit.items.fields.use_and_reproduction_statement.help_text_html',
                    url: Settings.links.use_and_reproduction_statement)
      return help_text unless @apo_defaults

      safe_join([help_text, tag.span(data: { apo_defaults_target: 'useAndReproductionStatementText' })], tag.br)
    end

    def input_data
      @apo_defaults ? { apo_defaults_target: 'useAndReproductionStatement' } : {}
    end
  end
end
