# frozen_string_literal: true

module Structure
  # Tabbed form navigation with columns matching TwoColumnWithHeaderComponent at xl.
  class TabListComponent < SdrViewComponents::TabForm::TabListComponent
    def initialize(**)
      super(tabs_classes: 'col-xl-2 col-md-3', panes_classes: 'col-xl-10 col-md-9', **)
    end
  end
end
