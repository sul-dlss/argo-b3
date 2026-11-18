# frozen_string_literal: true

module Edit
  # Component for rendering a field on the structure step for downloading a CSV of a Content and uploading it again
  # (e.g., the structural metadata or resource labels CSV). While uploading, the enclosing disable-actions
  # controller's actions (e.g., the resources' actions) are disabled.
  # The form's object must include SingleObjectCsvUploadConcern.
  class ContentCsvComponent < ApplicationComponent
    # Optional fields rendered inside the upload form, after the file field (e.g., "Allow files to be deleted").
    renders_one :additional_fields

    # @param model [SingleObjectCsvUploadConcern] the upload's form, with any errors from the last upload
    # @param url [String] where the upload is submitted
    # @param download_path [String] where the CSV is downloaded from
    # @param i18n_key [Symbol] the key of the section's copy under edit.contents.structure.csv (e.g., :structural)
    # @param submit_value [String] the commit value that selects the upload (see ContentsController)
    def initialize(model:, url:, download_path:, i18n_key:, submit_value:)
      @model = model
      @url = url
      @download_path = download_path
      @i18n_key = i18n_key
      @submit_value = submit_value
      super()
    end

    attr_reader :model, :url, :submit_value

    def download_label
      t("edit.contents.structure.csv.#{@i18n_key}.download")
    end

    def upload_label
      t("edit.contents.structure.csv.#{@i18n_key}.upload")
    end

    def help_text
      t("edit.contents.structure.csv.#{@i18n_key}.help")
    end

    def submit_label
      t("edit.contents.structure.csv.#{@i18n_key}.submit")
    end

    def download_link
      link_to(@download_path, download: true, data: { turbo: false }) do
        safe_join([helpers.download_icon(aria: { hidden: true }, classes: 'me-1'), download_label], ' ')
      end
    end

    def input_accept
      CsvUpload::Normalizer::SUPPORTED_FILE_EXTENSIONS.join(',')
    end
  end
end
