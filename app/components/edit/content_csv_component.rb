# frozen_string_literal: true

module Edit
  # Component for rendering a link to download a CSV of a Content and a form to upload it again on the structure step
  # (e.g., the structural or labels CSV). While uploading, the enclosing disable-actions controller's actions
  # (e.g., the resources' actions) are disabled.
  # The form's object must include SingleObjectCsvUploadConcern; when allow_file_deletion_field is true, it must
  # also provide allow_file_deletion.
  class ContentCsvComponent < ApplicationComponent
    # @param model [SingleObjectCsvUploadConcern] the upload's form, with any errors from the last upload
    # @param url [String] where the upload is submitted
    # @param download_path [String] where the CSV is downloaded from
    # @param download_label [String]
    # @param upload_label [String] the label of the file input
    # @param submit_label [String]
    # @param submit_value [String] the commit value that selects the upload (see ContentsController)
    # @param allow_file_deletion_field [Boolean] whether to render the "Allow files to be deleted" checkbox
    def initialize(model:, url:, download_path:, download_label:, upload_label:, submit_label:, submit_value:, # rubocop:disable Metrics/ParameterLists
                   allow_file_deletion_field: false)
      @model = model
      @url = url
      @download_path = download_path
      @download_label = download_label
      @upload_label = upload_label
      @submit_label = submit_label
      @submit_value = submit_value
      @allow_file_deletion_field = allow_file_deletion_field
      super()
    end

    attr_reader :model, :url, :download_path, :download_label, :upload_label, :submit_label, :submit_value,
                :allow_file_deletion_field

    def input_accept
      CsvUpload::Normalizer::SUPPORTED_FILE_EXTENSIONS.join(',')
    end
  end
end
