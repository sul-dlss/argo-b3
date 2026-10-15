# frozen_string_literal: true

module Edit
  # Component for rendering edit form for access rights
  class AccessRightsComponent < ApplicationComponent
    VIEW_RIGHTS = %w[world dark citation-only stanford location-based].freeze
    DOWNLOAD_RIGHTS = %w[world stanford location-based none].freeze

    # @param citation_only [Boolean] false to exclude the citation-only view option (e.g., for files)
    # @param apo_defaults_group [String, nil] the group of access fields that the apo-defaults Stimulus controller
    #   shows (and may apply) the selected APO's defaults to, or nil to not show APO defaults
    def initialize(form:, fieldname_prefix: nil, label_classes: [], container_classes: [], citation_only: true, # rubocop:disable Metrics/ParameterLists
                   apo_defaults_group: nil)
      @form = form
      @citation_only = citation_only
      @apo_defaults_group = apo_defaults_group
      @fieldname_prefix = fieldname_prefix
      @label_classes = label_classes
      @container_classes = container_classes
      super()
    end

    attr_reader :form, :fieldname_prefix, :apo_defaults_group

    def field_name_for(field_name)
      :"#{fieldname_prefix}#{field_name}"
    end

    def view_options
      view_rights = @citation_only ? VIEW_RIGHTS : VIEW_RIGHTS - ['citation-only']
      view_rights.map { |view_right| [AccessRightsSupport.view_or_download_label(view_right), view_right] }
    end

    def download_options
      DOWNLOAD_RIGHTS.map do |download_right|
        [AccessRightsSupport.view_or_download_label(download_right), download_right]
      end
    end

    def location_options
      Constants::ACCESS_LOCATIONS.map { |location| [AccessRightsSupport.location_label(location), location] }
    end

    def container_data
      return {} unless apo_defaults_group

      { apo_defaults_target: 'accessGroup', apo_defaults_group: }
    end

    # @param field [String] view, download, or location
    # @return [String, nil] a placeholder that the apo-defaults Stimulus controller fills with the APO's default
    def apo_default_help_text(field)
      return unless apo_defaults_group

      tag.span(data: { apo_defaults_field: field })
    end

    def label_classes
      merge_classes(@label_classes)
    end

    def container_classes
      merge_classes(@container_classes)
    end
  end
end
