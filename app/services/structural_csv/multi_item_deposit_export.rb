# frozen_string_literal: true

module StructuralCsv
  # Service for serializing the structure that File Check built for each Item Deposit of a Multi-Item Deposit to
  # one structural metadata CSV, which can be uploaded again. An Item Deposit whose structure was not built
  # (e.g., it has structural CSV errors) gets template rows instead.
  class MultiItemDepositExport
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

    def rows(&)
      item_deposit_actions.each do |item_deposit_action|
        content = item_deposit_action.content
        if item_deposit_action.structure_built?
          Export.new(content:).rows(&)
        else
          Template.content_rows(content:, &)
        end
      end
    end

    private

    attr_reader :multi_item_deposit_action

    def item_deposit_actions
      multi_item_deposit_action.item_deposit_actions_with_content
                               .includes(content: { content_file_sets: { content_files: :content_file_binary } })
    end
  end
end
