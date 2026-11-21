# frozen_string_literal: true

module Show
  # Component for the item page's Copy registration settings from dropdown, which opens Register an item or
  # Register multiple items prefilled with the item's settings.
  class CopyRegistrationSettingsDropdownComponent < ApplicationComponent
    # @param druid [String] the druid of the item
    # @param disabled [Boolean] true if the user can't register items with the item's APO and collections
    # @param classes [String] classes for the dropdown (e.g., its spacing in Elements::ButtonListComponent)
    def initialize(druid:, disabled: false, classes: [])
      @druid = druid
      @disabled = disabled
      @classes = classes
      super()
    end

    attr_reader :druid, :disabled

    def classes
      merge_classes('dropdown', @classes)
    end
  end
end
