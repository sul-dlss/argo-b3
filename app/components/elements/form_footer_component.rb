# frozen_string_literal: true

module Elements
  # Footer of a single-column form (BTN-3): Cancel, if any, then the actions given as content, primary action last.
  class FormFooterComponent < ApplicationComponent
    # @param cancel_path [String, nil] the URL Cancel links to; no Cancel is rendered when nil
    # @param confirm_cancel [Boolean] if Cancel should asks for confirmation that the user's changes will be lost
    # @param classes [Array<String>, String] additional classes for the footer
    def initialize(cancel_path: nil, confirm_cancel: false, classes: [])
      @cancel_path = cancel_path
      @confirm_cancel = confirm_cancel
      @classes = classes
      super()
    end

    attr_reader :cancel_path

    def cancel_data
      # Turbo confirms only links with a method, so Cancel is followed as a GET form submission.
      @confirm_cancel ? { turbo_method: :get, turbo_confirm: t('edit.cancel_confirm') } : {}
    end

    def classes
      merge_classes('d-flex align-items-center gap-3 mt-5', @classes)
    end
  end
end
