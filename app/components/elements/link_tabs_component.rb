# frozen_string_literal: true

module Elements
  # Underline tabs that each link to a separate page, so each tab is URL addressable.
  # Existing sdr_view_component tab view works within one page and has no link variant.
  class LinkTabsComponent < ApplicationComponent
    # @param label [String] text of the tab
    # @param path [String] URL of the tab's page
    # @param active [Boolean] whether the tab is the current page
    renders_many :tabs, lambda { |label:, path:, active: false|
      tag.li class: 'nav-item' do
        link_to label, path, class: merge_classes('nav-link', active ? 'active' : nil),
                             aria: { current: active ? 'page' : nil }
      end
    }

    # @param classes [Array<String>, String] additional classes for the tab list, e.g., for spacing
    def initialize(classes: [])
      @classes = classes
      super()
    end

    def call
      tag.ul class: merge_classes('nav nav-underline', @classes) do
        safe_join(tabs)
      end
    end
  end
end
