# frozen_string_literal: true

module Show
  # Component for displaying a file set (resource)
  class FileSetComponent < ApplicationComponent
    with_collection_parameter :content_file_set

    def initialize(content_file_set:, content_file_set_counter:, classes: [])
      @content_file_set = content_file_set
      @index = content_file_set_counter + 1
      @classes = classes
      super()
    end

    attr_reader :content_file_set, :index

    delegate :file_set_type, :label, to: :content_file_set

    def classes
      merge_classes('card file-set-card', @classes)
    end
  end
end
