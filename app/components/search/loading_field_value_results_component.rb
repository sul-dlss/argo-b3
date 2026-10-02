# frozen_string_literal: true

module Search
  # Component for displaying a placeholder while field value results are loading
  class LoadingFieldValueResultsComponent < ApplicationComponent
    def initialize(label:)
      @label = label
      super()
    end

    attr_reader :label

    def number_of_placeholders
      FieldValueResultsComponent::INITIAL_LIMIT
    end
  end
end
