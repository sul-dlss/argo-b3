# frozen_string_literal: true

# Form for updating structural metadata via CSV upload, replacing the structure (see SingleObjectCsvUploadConcern).
# Only the upload is validated here; the rows are validated by StructuralCsv::Import.
class StructuralCsvForm < ApplicationForm
  include SingleObjectCsvUploadConcern

  # Whether files omitted from the CSV may be deleted.
  attribute :allow_file_deletion, :boolean, default: false

  # @param content [Content] the mutable Content to update
  # @return [Dry::Monads::Result] see StructuralCsv::Import
  def import(content:)
    StructuralCsv::Import.call(rows: numbered_rows, content:, allow_file_deletion:)
  end
end
