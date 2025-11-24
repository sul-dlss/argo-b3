# frozen_string_literal: true

module Elements
  # Component for a selected item badge with a remove link.
  # Implements https://sul-dlss.github.io/component-library/selected_item/
  class SelectedItemComponent < ViewComponent::Base
    def initialize(label:, path:)
      @label = label
      @path = path
      super()
    end

    attr_reader :label, :path
  end
end
