# frozen_string_literal: true

module Elements
  # Component for a delete button
  class DeleteButtonComponent < SdrViewComponents::Elements::IconButtonComponent
    def initialize(label: 'Remove', **args)
      super(icon: :delete, label:, classes: merge_classes(classes, 'px-0'), **args)
    end
  end
end
