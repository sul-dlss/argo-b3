# frozen_string_literal: true

module Search
  # Component for navigating back to search results or between individual search results.
  class ItemNavigationComponent < ApplicationComponent
    def initialize(last_search_form:, current_position:, total_results:, previous_druid:, next_druid:)
      @last_search_form = last_search_form
      @current_position = current_position
      @total_results = total_results
      @previous_druid = previous_druid
      @next_druid = next_druid
      super()
    end

    def render?
      last_search_form.present?
    end

    private

    attr_reader :last_search_form, :current_position, :total_results, :previous_druid, :next_druid

    def item_navigation?
      current_position.present? && total_results.present?
    end

    def previous_path
      object_path(druid: previous_druid, search_position: current_position - 1)
    end

    def next_path
      object_path(druid: next_druid, search_position: current_position + 1)
    end
  end
end
