# frozen_string_literal: true

module Search
  # Component for "Previous"/"Next" links to move between items within the current search results.
  class ItemNavigationComponent < ApplicationComponent
    def initialize(current_position:, total_results:, previous_druid:, next_druid:)
      @current_position = current_position
      @total_results = total_results
      @previous_druid = previous_druid
      @next_druid = next_druid
      super()
    end

    attr_reader :current_position, :total_results, :previous_druid, :next_druid

    def render?
      current_position.present?
    end

    def previous_link
      return '#' if previous_druid.blank?

      object_path(druid: previous_druid, search_position: current_position - 1)
    end

    def next_link
      return '#' if next_druid.blank?

      object_path(druid: next_druid, search_position: current_position + 1)
    end
  end
end
