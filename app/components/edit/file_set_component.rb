# frozen_string_literal: true

module Edit
  # Component for editing a file set (resource)
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
      merge_classes('card file-set-card', @classes)
    end

    def path
      content_content_file_set_path(@content_token, content_file_set_form, counter:)
    end

    def file_set_type_options
      FileSetTypes::ALL
    end
  end
end
