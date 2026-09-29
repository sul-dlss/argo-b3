# frozen_string_literal: true

module Show
  # Component for displaying a file binary of a content, with a button to delete it.
  class ContentFileBinaryComponent < ApplicationComponent
    # @param content_file_binary [ContentFileBinary]
    # @param content_file_sets [Array<ContentFileSet>] all of the content's file sets (in order) with their files
    # @param content_token [String] signed content id
    # @param disabled [Boolean] true to disable deleting
    def initialize(content_file_binary:, content_file_sets:, content_token:, disabled: false)
      @content_file_binary = content_file_binary
      @content_file_sets = content_file_sets
      @content_token = content_token
      @disabled = disabled
      super()
    end

    delegate :filepath, to: :content_file_binary

    def delete_path
      content_content_file_binary_path(content_token, content_file_binary)
    end

    def disabled?
      @disabled
    end

    # Confirm only when deleting would also delete resources.
    # @return [String, nil] confirmation message
    def confirm
      return if emptied_resource_indexes.empty?

      t('edit.content_file_binaries.buttons.delete_confirm', filepath:, count: emptied_resource_indexes.size,
                                                             indexes: emptied_resource_indexes.to_sentence)
    end

    private

    attr_reader :content_file_binary, :content_file_sets, :content_token

    # A resource is emptied (and so deleted) when all of its files reference this binary.
    # @return [Array<Integer>] the indexes (as displayed) of the resources that deleting would empty
    def emptied_resource_indexes
      @emptied_resource_indexes ||= content_file_sets.each_with_index.filter_map do |content_file_set, index|
        content_files = content_file_set.content_files
        next if content_files.empty?
        next unless content_files.all? { |content_file| content_file.content_file_binary_id == content_file_binary.id }

        index + 1
      end
    end
  end
end
