# frozen_string_literal: true

module Edit
  # Component for rendering edit form for license
  class LicenseComponent < ApplicationComponent
    def initialize(form:, container_classes: [], label_text: nil, hide_help_text: false)
      @form = form
      @container_classes = container_classes
      @label_text = label_text
      @hide_help_text = hide_help_text
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
      t('edit.items.fields.license.help_text') unless @hide_help_text
    end
  end
end
