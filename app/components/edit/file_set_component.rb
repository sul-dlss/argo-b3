# frozen_string_literal: true

module Edit
  # Component for editing a file set (resource): a header with its type and label, then a table of its files,
  # one row per file (see Edit::ContentFileComponent).
  # The content file set form must provide file_set_type, label, and content_files (with allow_destroy).
  class FileSetComponent < ApplicationComponent
    def initialize(content_file_set_form:, counter:, content_token:, classes: [])
      @content_file_set_form = content_file_set_form
      @counter = counter
      @classes = classes
      @content_token = content_token
      super()
    end

    attr_reader :content_file_set_form, :counter

    def index
      counter + 1
    end

    def classes
      merge_classes('file-set-card', @classes)
    end

    def path
      content_content_file_set_path(@content_token, content_file_set_form, counter:)
    end

    def file_set_type_options
      FileSetTypes::ALL
    end

    # A column header with the required marker. The marker is hidden from screen readers, since each input
    # in the column is announced as required.
    # @param field [Symbol] the field of the column, e.g., :mime_type
    def required_header(field)
      safe_join([t("edit.content_file_sets.fields.content_files.#{field}.label"), ' ',
                 tag.span('*', class: 'required', aria: { hidden: true })])
    end
  end
end
