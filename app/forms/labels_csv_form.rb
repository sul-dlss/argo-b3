# frozen_string_literal: true

# Form for updating the labels of a Content's resources via a labels CSV upload (see SingleObjectCsvUploadConcern).
# Only the upload is validated here; the rows are validated by LabelsCsv::Import.
class LabelsCsvForm < ApplicationForm
  include SingleObjectCsvUploadConcern

  # @param content [Content] the mutable Content to update
  # @return [Dry::Monads::Result] see LabelsCsv::Import
  def import(content:)
    LabelsCsv::Import.call(rows: numbered_rows, content:)
  end
end
