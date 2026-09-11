# frozen_string_literal: true

module Edit
  # Component for rendering edit form for access rights
  class AccessRightsComponent < ApplicationComponent
    VIEW_RIGHTS = %w[world dark citation-only stanford location-based].freeze
    DOWNLOAD_RIGHTS = %w[world stanford location-based none].freeze

    def initialize(form:, fieldname_prefix: nil, label_classes: [], container_classes: [])
      @form = form
      @fieldname_prefix = fieldname_prefix
      @label_classes = label_classes
      @container_classes = container_classes
      super()
    end

    attr_reader :form, :fieldname_prefix

    def field_name_for(field_name)
      :"#{fieldname_prefix}#{field_name}"
    end

    def view_options
      VIEW_RIGHTS.map { |view_right| [view_right.titleize, view_right] }
    end

    def download_options
      DOWNLOAD_RIGHTS.map { |download_right| [download_right.titleize, download_right] }
    end

    def location_options
      Constants::ACCESS_LOCATIONS.map { |location| [I18n.t("access.locations.#{location}"), location] }
    end

    def label_classes
      merge_classes(@label_classes)
    end

    def container_classes
      merge_classes(@container_classes)
    end
  end
end
