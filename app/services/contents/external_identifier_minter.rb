# frozen_string_literal: true

module Contents
  # Mints an external identifier for any ContentFileSet or ContentFile in a Content that is missing one, following
  # the minting strategy in
  # https://github.com/sul-dlss/hungry-hungry-hippo/blob/main/app/mappers/cocina/work_structural_mapper.rb
  class ExternalIdentifierMinter
    ID_NAMESPACE = 'https://cocina.sul.stanford.edu'

    def self.call(...)
      new(...).call
    end

    # @param [Content] content
    def initialize(content:)
      @content = content
    end

    def call
      content.content_file_sets.each do |content_file_set|
        update_file_set_identifier!(content_file_set)
        content_file_set.content_files.each { |content_file| update_file_identifier!(content_file) }
      end
    end

    private

    attr_reader :content

    def bare_druid
      DruidSupport.bare_druid_from(content.druid)
    end

    def update_file_set_identifier!(content_file_set)
      return if content_file_set.external_identifier.present?

      content_file_set.update!(external_identifier: "#{ID_NAMESPACE}/fileSet/#{bare_druid}-#{SecureRandom.uuid}")
    end

    def update_file_identifier!(content_file)
      return if content_file.external_identifier.present?

      content_file.update!(external_identifier: "#{ID_NAMESPACE}/file/#{bare_druid}-#{SecureRandom.uuid}")
    end
  end
end
