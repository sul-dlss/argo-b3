# frozen_string_literal: true

module Edit
  # Component for the structure step's collapsible "Use a spreadsheet" section: links to download the structural
  # metadata and labels CSVs of a Content, and a toggle choosing which of them to upload. Each CSV is uploaded by its
  # own form, of which only the selected one is shown.
  # The forms' objects must include SingleObjectCsvUploadConcern; the structural one must also provide
  # allow_file_deletion (StructuralCsvForm).
  class ContentCsvSectionComponent < ApplicationComponent
    STRUCTURAL = 'structural'
    LABELS = 'labels'

    # The toggle's form object, holding the selected CSV type.
    class UploadSelection
      include ActiveModel::Model

      attr_accessor :csv_type
    end

    # @param structural_csv_form [StructuralCsvForm] with any errors from the last structural CSV upload
    # @param labels_csv_form [LabelsCsvForm] with any errors from the last labels CSV upload
    # @param url [String] where the uploads are submitted
    # @param csv_download_path [String] where the structural metadata CSV is downloaded from
    # @param labels_csv_download_path [String] where the labels CSV is downloaded from
    def initialize(structural_csv_form:, labels_csv_form:, url:, csv_download_path:, labels_csv_download_path:)
      @structural_csv_form = structural_csv_form
      @labels_csv_form = labels_csv_form
      @url = url
      @csv_download_path = csv_download_path
      @labels_csv_download_path = labels_csv_download_path
      super()
    end

    attr_reader :structural_csv_form, :labels_csv_form, :url, :csv_download_path, :labels_csv_download_path

    # Expanded after a failed upload, so that its errors are visible.
    def expanded?
      structural_csv_form.errors.any? || labels_csv_form.errors.any?
    end

    # The labels CSV is selected only after a failed labels CSV upload.
    def selected_csv_type
      labels_csv_form.errors.any? ? LABELS : STRUCTURAL
    end

    def upload_selection
      UploadSelection.new(csv_type: selected_csv_type)
    end

    # The section's classes for a CSV type. The toggle controller shows and hides the sections in the browser; they are
    # also rendered shown or hidden, so that a morph after a failed upload keeps the failed CSV type's section shown.
    def section_classes(csv_type)
      csv_type == selected_csv_type ? nil : 'd-none'
    end

    def download_link(path:, label:)
      link_to(path, download: true, data: { turbo: false }) do
        safe_join([tag.span("#{t('edit.contents.structure.csv.download')} ", class: 'visually-hidden'), label])
      end
    end

    def input_accept
      CsvUpload::Normalizer::SUPPORTED_FILE_EXTENSIONS.join(',')
    end

    def form_data
      helpers.disable_actions_form_data
    end
  end
end
