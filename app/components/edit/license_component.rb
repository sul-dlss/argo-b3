# frozen_string_literal: true

module Edit
  # Component for rendering edit form for license
  class LicenseComponent < ApplicationComponent
    def initialize(form:, container_classes: [])
      @form = form
      @container_classes = container_classes
      super()
    end

    attr_reader :form

    def options
      [['', nil]] + Constants::LICENSE_OPTIONS.map { |option| [option[:label], option[:uri]] }
    end

    def label_caption
      helpers.link_to_new_tab(t('edit.items.fields.license.label_caption'), Settings.links.license)
    end

    def container_classes
      merge_classes(@container_classes)
    end
  end
end
