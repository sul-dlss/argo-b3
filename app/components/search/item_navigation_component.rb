# frozen_string_literal: true

module Search
  # Component for navigating back to search results or between individual search results.
  class ItemNavigationComponent < ApplicationComponent
    def initialize(last_search_form:, current_position:, navigation:)
      @last_search_form = last_search_form
      @current_position = current_position
      @navigation = navigation
      super()
    end

    def render?
      last_search_form.present?
    end

    private

    attr_reader :last_search_form, :current_position, :navigation

    def item_navigation?
      current_position.present? && navigation.present?
    end

    def previous_druid
      navigation.previous_druid
    end

    def next_druid
      navigation.next_druid
    end

    def total_results
      navigation.total_results
    end

    def previous_path
      object_path(druid: previous_druid, search_position: current_position - 1)
    end

    def next_path
      object_path(druid: next_druid, search_position: current_position + 1)
    end

    def previous_label
      '« Previous'
    end

    def next_label
      'Next »'
    end
  end
end
