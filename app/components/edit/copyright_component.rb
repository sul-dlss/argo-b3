# frozen_string_literal: true

module Edit
  # Component for rendering edit form for copyright
  # The form's object must include CocinaModels::AccessConcern.
  class CopyrightComponent < ApplicationComponent
    INPUT_ROWS = 3

    # @param apo_defaults [Boolean] true to show the selected APO's default copyright, using the
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
      @label_text || t('edit.items.fields.copyright.label')
    end

    def help_text
      help_text = t('edit.items.fields.copyright.help_text_html', url: Settings.links.copyright)
      return help_text unless @apo_defaults

      safe_join([help_text, tag.span(data: { apo_defaults_target: 'copyrightText' })], tag.br)
    end

    def input_data
      @apo_defaults ? { apo_defaults_target: 'copyright' } : {}
    end
  end
end
