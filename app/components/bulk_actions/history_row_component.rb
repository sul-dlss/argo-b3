# frozen_string_literal: true

module BulkActions
  # Component for rendering a row of the bulk actions history table
  class HistoryRowComponent < ApplicationComponent
    # @param admin [Boolean] whether to include the user column
    def initialize(bulk_action:, admin:)
      @bulk_action = bulk_action
      @admin = admin
      super()
    end

    attr_reader :bulk_action

    def admin?
      @admin
    end

    private

    def log_file_link
      return unless bulk_action.log_file?

      link_to('Log file', file_bulk_action_path(bulk_action, filename: bulk_action.log_filename), download: true)
    end

    def export_links
      return unless bulk_action.existing_exports

      bulk_action.existing_exports.map do |export|
        link_to(export.label, file_bulk_action_path(bulk_action, filename: export.filename), download: true)
      end
    end

    def download_links
      links = Array(log_file_link) + Array(export_links).compact
      return if links.blank?

      tag.ul { safe_join(links.map { |link| tag.li(link) }) }
    end

    def cancellable_and_allowed?
      bulk_action.cancellable? && helpers.allowed_to?(:cancel?, bulk_action)
    end
  end
end
