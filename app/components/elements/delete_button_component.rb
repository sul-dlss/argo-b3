# frozen_string_literal: true

module Elements
  # Component for a delete button
  class DeleteButtonComponent < SdrViewComponents::Elements::IconButtonComponent
    def initialize(label: 'Remove', classes: 'px-0', **)
      super(icon: :delete, label:, classes:, **)
    end
  end
end
