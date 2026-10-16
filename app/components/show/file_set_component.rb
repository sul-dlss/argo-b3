# frozen_string_literal: true

module Show
  # Component for displaying a file set (resource)
  class FileSetComponent < ApplicationComponent
    with_collection_parameter :content_file_set

    def initialize(content_file_set:, content_file_set_counter:, content_file_set_total:, classes: [],
                   content_token: nil)
      @content_file_set = content_file_set
      @counter = content_file_set_counter
      # The number of resources in the content, used to determine whether this resource can move down.
      @content_file_set_total = content_file_set_total
      @classes = classes
      # Provide content_token to make editable.
      @content_token = content_token
      super()
    end

    attr_reader :content_file_set, :counter

    delegate :file_set_type, :label, to: :content_file_set

    def index
      counter + 1
    end

    def classes
      merge_classes('card file-set-card', @classes)
    end

    def editable?
      @content_token.present?
    end

    def edit_path
      edit_content_content_file_set_path(@content_token, content_file_set, counter:)
    end

    def delete_path
      content_content_file_set_path(@content_token, content_file_set)
    end

    def move_up?
      editable? && counter.positive?
    end

    def move_down?
      editable? && index < @content_file_set_total
    end

    def move_path(direction)
      move_content_content_file_set_path(@content_token, content_file_set, direction:)
    end
  end
end
