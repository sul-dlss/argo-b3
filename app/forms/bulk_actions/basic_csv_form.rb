# frozen_string_literal: true

module BulkActions
  # Form object that only includes the basic attributes including a CSV file.
  # This can be used by itself or as a superclass for more complex forms.
  class BasicCsvForm < ApplicationForm
    attribute :csv_file, :uploaded_file
    validates :csv_file, presence: true

    attribute :description, :string

    # Only applies to some bulk actions.
    # For those bulk actions, with_close_version to true for BulkActions::FormComponent.
    attribute :close_version, :boolean, default: true

    def normalized_csv_file
      @normalized_csv_file ||= CsvUpload::Normalizer.read(csv_file.path)
    end
  end
end
