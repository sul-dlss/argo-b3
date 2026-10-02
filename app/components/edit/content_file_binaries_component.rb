# frozen_string_literal: true

module Edit
  # Component for displaying a table of the file binaries of a content, with a button to delete each.
  class ContentFileBinariesComponent < Show::ContentFileBinariesComponent
    # @param content_record [Content] (named to avoid ViewComponent's reserved content parameter)
    # @param content_token [String] signed content id
    # @param disabled [Boolean] true to disable deleting
    def initialize(content_record:, content_token:, disabled: false)
      @content_token = content_token
      @disabled = disabled
      super(content_record:)
    end

    def delete_path(content_file_binary)
      content_content_file_binary_path(content_token, content_file_binary)
    end

    def disabled?
      @disabled
    end

    # Confirm only when deleting would also delete resources.
    # @return [String, nil] confirmation message
    def confirm(content_file_binary)
      indexes = emptied_resource_indexes[content_file_binary.id]
      return if indexes.blank?

      t('edit.content_file_binaries.buttons.delete_confirm', filepath: content_file_binary.filepath,
                                                             count: indexes.size,
                                                             indexes: indexes.to_sentence)
    end

    private

    attr_reader :content_token

    # A resource is emptied (and so deleted) when all of its files reference the same binary.
    # @return [Hash{Integer => Array<Integer>}] binary id => the indexes (as displayed) of the resources
    #   that deleting the binary would empty
    def emptied_resource_indexes
      @emptied_resource_indexes ||= {}.tap do |indexes|
        content_record.content_file_sets.each_with_index do |content_file_set, index|
          content_file_binary_ids = content_file_set.content_files.map(&:content_file_binary_id).uniq
          next unless content_file_binary_ids.one?

          (indexes[content_file_binary_ids.first] ||= []) << (index + 1)
        end
      end
    end
  end
end
