# frozen_string_literal: true

module StructuralCsv
  # Service for serializing the structural metadata of a Content to CSV
  class Export
    HEADERS = %w[druid resource_label resource_type sequence filename file_label publish
                 shelve preserve rights_view rights_download rights_location mimetype
                 role file_language sdr_generated_text corrected_for_accessibility].freeze

    def self.as_csv(content:)
      new(content:).as_csv
    end

    # @param content [Content] the Content to serialize (which may be unsaved, e.g., from Contents::Builder.build)
    def initialize(content:)
      @content = content
      @druid = DruidSupport.bare_druid_from(content.druid)
    end

    def as_csv
      CSV.generate(headers: true) do |csv|
        csv << HEADERS
        rows do |row|
          csv << row
        end
      end
    end

    def rows # rubocop:disable Metrics/AbcSize
      content.content_file_sets.each.with_index(1) do |content_file_set, sequence|
        content_file_set.content_files.each do |content_file|
          yield [@druid, content_file_set.label, content_file_set.file_set_type, sequence, content_file.filepath,
                 content_file.label, to_yes_no(content_file.publish), to_yes_no(content_file.shelve),
                 to_yes_no(content_file.preserve), content_file.view, content_file.download, content_file.location,
                 content_file.mime_type, content_file.use, content_file.language_tag, content_file.sdr_generated_text,
                 content_file.corrected_for_accessibility]
        end
      end
    end

    private

    attr_reader :content

    def to_yes_no(bool)
      bool ? 'yes' : 'no'
    end
  end
end
