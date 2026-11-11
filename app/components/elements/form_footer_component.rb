# frozen_string_literal: true

module Elements
  # Footer of a single-column form (BTN-3): Cancel, if any, then the actions given as content, primary action last.
  class FormFooterComponent < ApplicationComponent
    # @param cancel_path [String, nil] the URL Cancel links to; no Cancel is rendered when nil
    # @param classes [Array<String>, String] additional classes for the footer
    def initialize(cancel_path: nil, classes: [])
      @cancel_path = cancel_path
      @classes = classes
      super()
    end

    attr_reader :cancel_path

    def classes
      merge_classes('d-flex align-items-center gap-3 mt-5', @classes)
    end
  end
end
