# frozen_string_literal: true

module DiscoveryReportCsv
  # Service for generating the report of the results of checking a Multi-Item Deposit's manifest (discovery):
  # a row for every Item Deposit, in manifest order, with its discovery errors and warnings (if any).
  class Export
    HEADERS = ['Manifest line number', 'Druid', 'Folder', 'Content type', 'Error', 'Warning'].freeze
    MESSAGE_SEPARATOR = '; '

    def self.as_csv(multi_item_deposit_action:)
      new(multi_item_deposit_action:).as_csv
    end

    # @param multi_item_deposit_action [MultiItemDepositAction]
    def initialize(multi_item_deposit_action:)
      @multi_item_deposit_action = multi_item_deposit_action
    end

    def as_csv
      CSV.generate(headers: true) do |csv|
        csv << HEADERS
        item_deposit_actions.each do |item_deposit_action|
          csv << row_for(item_deposit_action)
        end
      end
    end

    private

    attr_reader :multi_item_deposit_action

    def item_deposit_actions
      multi_item_deposit_action.item_deposit_actions.order(:manifest_line_number)
    end

    def row_for(item_deposit_action)
      [
        item_deposit_action.manifest_line_number,
        DruidSupport.bare_druid_from(item_deposit_action.druid),
        item_deposit_action.path,
        content_type_for(item_deposit_action),
        # Blank rather than "" when there are no messages
        item_deposit_action.discovery_errors.join(MESSAGE_SEPARATOR).presence,
        item_deposit_action.discovery_warnings.join(MESSAGE_SEPARATOR).presence
      ]
    end

    # The display name, as in the summary's content types (e.g., "file" for object)
    def content_type_for(item_deposit_action)
      return if item_deposit_action.content_type.blank?

      ContentTypeSupport.display_name(item_deposit_action.content_type)
    end
  end
end
