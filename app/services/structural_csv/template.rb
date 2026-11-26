# frozen_string_literal: true

module StructuralCsv
  # Service for generating a structural metadata CSV template for a Multi-Item Deposit:
  # a row for each discovered file, pre-populated with the druid, filename, and mimetype.
  class Template
    def self.as_csv(multi_item_deposit_action:)
      new(multi_item_deposit_action:).as_csv
    end

    # Yields a template row for each file of a Content.
    # @param content [Content]
    def self.content_rows(content:)
      druid = DruidSupport.bare_druid_from(content.druid)
      content.content_file_binaries.path_order.each do |content_file_binary|
        values = { 'druid' => druid, 'filename' => content_file_binary.filepath,
                   'mimetype' => content_file_binary.mime_type }
        yield Export::HEADERS.map { |header| values[header] }
      end
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

    def rows(&)
      multi_item_deposit_action.item_deposit_actions_with_content.each do |item_deposit_action|
        self.class.content_rows(content: item_deposit_action.content, &)
      end
    end

    private

    attr_reader :multi_item_deposit_action
  end
end
