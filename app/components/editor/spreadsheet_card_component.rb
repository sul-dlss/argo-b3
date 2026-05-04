# frozen_string_literal: true

class Editor::SpreadsheetCardComponent < ApplicationComponent
  def initialize(spreadsheet_hash:)
    @spreadsheet_hash = spreadsheet_hash
    super()
  end

  private

  attr_reader :spreadsheet_hash
end
