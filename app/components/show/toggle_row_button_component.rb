# frozen_string_literal: true

module Show
  # Button in the first cell of a table row that shows / hides the following details row.
  # The row is given ROW_OPTIONS so that clicking anywhere on it also toggles it, via the button.
  class ToggleRowButtonComponent < ApplicationComponent
    ROW_OPTIONS = { class: 'toggle-row', data: { controller: 'toggle-row', action: 'click->toggle-row#toggle' } }.freeze

    # @param details_row_id [String] id of the details row
    # @param label [String] visually hidden accessible name of the button
    def initialize(details_row_id:, label:)
      @details_row_id = details_row_id
      @label = label
      super()
    end

    def call
      render SdrViewComponents::Elements::IconButtonComponent.new(
        icon: :toggle_row, label: @label, classes: 'toggle-row-button collapsed',
        data: { bs_toggle: 'collapse', bs_target: "##{@details_row_id}", toggle_row_target: 'button' },
        aria: { expanded: false, controls: @details_row_id }
      )
    end
  end
end
