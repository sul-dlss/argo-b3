# frozen_string_literal: true

module Elements
  # Component for the sort pulldown on search results.
  class SortComponent < ApplicationComponent
    renders_one :button, lambda { |label:|
      SdrViewComponents::Elements::ButtonComponent.new(label:,
                                                       classes: 'btn btn-outline-primary ms-3 dropdown-toggle',
                                                       data: { 'bs-toggle': 'dropdown' },
                                                       aria: { expanded: false })
    }
    renders_many :sort_options, lambda { |label:, path:|
      link_to label, path, class: 'dropdown-item', role: 'menuitem'
    }
  end
end
