# frozen_string_literal: true

module StructuralCsv
  # A problem with a structural metadata CSV, with the spreadsheet row number (1 for the header row) it applies to.
  ValidationError = Struct.new(:line_number, :reason)
end
