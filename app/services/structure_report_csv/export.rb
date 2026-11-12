# frozen_string_literal: true

module StructureReportCsv
  # Service for generating the report of the results of checking a Multi-Item Deposit's files (structuring):
  # the summary table's rows with a row per error or warning, errors first, then warnings, then OK Item Deposits.
  class Export
    HEADER_KEYS = %i[druid folder file_count content_type deposit_type status message].freeze

    def self.as_csv(multi_item_deposit_action:)
      new(multi_item_deposit_action:).as_csv
    end

    # @param multi_item_deposit_action [MultiItemDepositAction]
    def initialize(multi_item_deposit_action:)
      @structure_results = MultiItemDeposit::StructureResults.new(multi_item_deposit_action:)
    end

    def as_csv
      CSV.generate do |csv|
        csv << HEADER_KEYS.map { |key| I18n.t("multi_item_deposit.summary.headers.#{key}") }
        rows.each { |row| csv << row }
      end
    end

    private

    attr_reader :structure_results

    # Grouped by status, keeping the summary table's order within each group.
    def rows
      rows_by_kind = { error: [], warning: [], ok: [] }
      structure_results.item_deposit_actions.each do |item_deposit_action|
        columns = columns_for(item_deposit_action)
        statuses_for(item_deposit_action).each do |kind, message|
          rows_by_kind[kind] << (columns + [status(kind), message])
        end
      end
      rows_by_kind.values.flatten(1)
    end

    # @return [Array<Array(Symbol, String)>] the kind (:error, :warning, or :ok) and message of each status
    def statuses_for(item_deposit_action)
      errors = item_deposit_action.structure_errors.map { |message| [:error, message] }
      warnings = item_deposit_action.content_type_structure_warnings.map { |message| [:warning, message] }
      (errors + warnings).presence || [[:ok, nil]]
    end

    def status(kind)
      I18n.t("multi_item_deposit.summary.report_statuses.#{kind}")
    end

    def columns_for(item_deposit_action)
      [
        DruidSupport.bare_druid_from(item_deposit_action.druid),
        item_deposit_action.path,
        structure_results.file_count(item_deposit_action),
        ContentTypeSupport.display_name(item_deposit_action.content_type),
        I18n.t("multi_item_deposit.summary.deposit_types.#{item_deposit_action.deposit_type}")
      ]
    end
  end
end
