# frozen_string_literal: true

module Structure
  # Component for a page layout with a header strip above a left-nav / main-content two-column row.
  class TwoColumnWithHeaderComponent < ApplicationComponent
    renders_one :top_content
    renders_one :left_content
    renders_one :main_content
  end
end
