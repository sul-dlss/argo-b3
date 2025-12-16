# frozen_string_literal: true

module BulkActions
  # Component for rendering a section of bulk actions
  class ListSectionComponent < ApplicationComponent
    def initialize(label:, bulk_action_configs:, classes: [])
      @label = label
      @classes = classes
      @bulk_action_configs = bulk_action_configs
      super()
    end

    attr_reader :label, :bulk_action_configs

    def classes
      merge_classes(@classes)
    end

    def id
      "#{label.parameterize}-bulk-actions-section"
    end
  end
end
