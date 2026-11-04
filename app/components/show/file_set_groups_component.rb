# frozen_string_literal: true

module Show
  # Component for displaying the resources of a content, grouped by the resource types that suit its content type.
  class FileSetGroupsComponent < ApplicationComponent
    # Content type to the label and resource types of its primary group; other resources are supplemental files.
    PRIMARY_GROUPS = {
      Cocina::Models::ObjectType.book => ['Pages', [FileSetTypes::PAGE]],
      Cocina::Models::ObjectType.image => ['Images', [FileSetTypes::IMAGE]],
      Cocina::Models::ObjectType.map => ['Images', [FileSetTypes::IMAGE]],
      Cocina::Models::ObjectType.media => ['Media', [FileSetTypes::AUDIO, FileSetTypes::VIDEO, FileSetTypes::IMAGE]],
      Cocina::Models::ObjectType.document => ['Documents', [FileSetTypes::DOCUMENT]]
    }.freeze

    Group = Struct.new(:label, :indexed_content_file_sets) do
      def id
        "file-set-group-#{label.parameterize}"
      end

      def heading
        "#{label} (#{indexed_content_file_sets.size})"
      end
    end

    # @param content_file_sets [Array<ContentFileSet>] the ordered resources of the content
    # @param content_type [String] the cocina object type URI
    def initialize(content_file_sets:, content_type:)
      @content_file_sets = content_file_sets
      @content_type = content_type
      super()
    end

    attr_reader :content_file_sets

    def grouped?
      PRIMARY_GROUPS.key?(@content_type)
    end

    # @return [Array<Group>] the non-empty groups, primary group first
    def groups
      label, file_set_types = PRIMARY_GROUPS.fetch(@content_type)
      primary, supplemental = indexed_content_file_sets.partition do |content_file_set, _index|
        file_set_types.include?(content_file_set.file_set_type)
      end
      [Group.new(label:, indexed_content_file_sets: primary),
       Group.new(label: 'Supplemental files', indexed_content_file_sets: supplemental)]
        .reject { |group| group.indexed_content_file_sets.empty? }
    end

    # @return [Array<Array(ContentFileSet, Integer)>] each resource with its position in the content
    def indexed_content_file_sets
      content_file_sets.each_with_index.to_a
    end
  end
end
