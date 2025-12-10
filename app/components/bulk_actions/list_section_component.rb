# frozen_string_literal: true

module BulkActions
  # Component for rendering a section of bulk actions
  class ListSectionComponent < ApplicationComponent
    renders_many :bulk_actions, lambda { |key:, path:|
      safe_join([
                  link_to(I18n.t("bulk_actions.#{key}.label"), path),
                  tag.p(class: 'mb-0') do
                    tag.small do
                      I18n.t("bulk_actions.#{key}.help_html").html_safe
                    end
                  end
                ])
    }

    def initialize(label:, classes: [])
      @label = label
      @classes = classes
      super()
    end

    attr_reader :label

    def classes
      merge_classes(@classes)
    end

    def id
      "#{label.parameterize}-bulk-actions-section"
    end
  end
end
