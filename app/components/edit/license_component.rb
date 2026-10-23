# frozen_string_literal: true

module Edit
  # Component for rendering edit form for license
  # The form's object must include CocinaModels::AccessConcern.
  class LicenseComponent < ApplicationComponent
    # @param apo_defaults [Boolean] true to show the selected APO's default license, using the apo-defaults
    #   Stimulus controller
    def initialize(form:, container_classes: [], label_text: nil, hide_help_text: false, apo_defaults: false)
      @form = form
      @container_classes = container_classes
      @label_text = label_text
      @hide_help_text = hide_help_text
      @apo_defaults = apo_defaults
      super()
    end

    attr_reader :form

    def options
      [['', nil]] + Constants::LICENSE_OPTIONS.map { |option| [option[:label], option[:uri]] }
    end

    def label_caption
      t('edit.items.fields.license.label_caption_html', url: Settings.links.license)
    end

    def container_classes
      merge_classes(@container_classes)
    end

    def label_text
      @label_text || t('edit.items.fields.license.label')
    end

    def help_text
      help_texts = []
      help_texts << t('edit.items.fields.license.help_text') unless @hide_help_text
      help_texts << tag.span(data: { apo_defaults_target: 'licenseText' }) if @apo_defaults
      safe_join(help_texts, tag.br).presence
    end

    def input_data
      @apo_defaults ? { apo_defaults_target: 'license' } : {}
    end
  end
end
