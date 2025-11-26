# frozen_string_literal: true

module Elements
  # Component for a selected item badge with a remove link.
  # Implements https://sul-dlss.github.io/component-library/selected_item/
  class SelectedItemComponent < ViewComponent::Base
    renders_one :label_content

    def initialize(path:, label: nil)
      @label = label # Provide label or label_content
      @path = path
      super()
    end

    attr_reader :label, :path
  end
end
