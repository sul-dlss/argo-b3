# frozen_string_literal: true

module StructuralCsv
  # Service for generating a structural metadata CSV template for a Multi-Item Deposit:
  # a row for each discovered file, pre-populated with the druid, filename, and mimetype.
  class Template
    def self.as_csv(multi_item_deposit_action:)
      new(multi_item_deposit_action:).as_csv
    end

    # @param multi_item_deposit_action [MultiItemDepositAction]
    def initialize(multi_item_deposit_action:)
      @multi_item_deposit_action = multi_item_deposit_action
    end

    def as_csv
      CSV.generate(headers: true) do |csv|
        csv << Export::HEADERS
        rows do |row|
          csv << row
        end
      end
    end

    def rows
      # Item Deposits without a Content (e.g., with discovery errors) have no files.
      item_deposit_actions.each do |item_deposit_action|
        druid = DruidSupport.bare_druid_from(item_deposit_action.druid)
        item_deposit_action.content.content_file_binaries.path_order.each do |content_file_binary|
          values = { 'druid' => druid, 'filename' => content_file_binary.filepath,
                     'mimetype' => content_file_binary.mime_type }
          yield Export::HEADERS.map { |header| values[header] }
        end
      end
    end

    private

    attr_reader :multi_item_deposit_action

    def item_deposit_actions
      multi_item_deposit_action.item_deposit_actions.where.not(content_id: nil).includes(:content)
                               .order(:manifest_line_number)
    end
  end
end
