# frozen_string_literal: true

module Search
  # Component for the layout of the search page, with sidebar and main content areas.
  class LayoutComponent < ViewComponent::Base
    renders_one :sidebar
    renders_one :main_content
  end
end
