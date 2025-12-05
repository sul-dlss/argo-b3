# frozen_string_literal: true

module Report
  # Component for rendering a section of report fields
  # This is used in the report form to group fields into sections.
  class FieldsSectionComponent < ApplicationComponent
    # @param form [ActionView::Helpers::FormBuilder]
    # @param label [String]
    # @param field_configs [Array<Reports::Fields::Config>]
    def initialize(form:, label:, field_configs:, classes: nil)
      @form = form
      @label = label
      @field_configs = field_configs
      @classes = classes
      super()
    end

    attr_reader :form, :label, :field_configs

    def classes
      merge_classes('fst-italic mb-1', @classes)
    end
  end
end
