# frozen_string_literal: true

module BulkActions
  # Job to start text extraction workflow for objects
  class TextExtractionJob < DruidsJob
    def perform(bulk_action:, druids:, text_extraction_languages: [])
      @text_extraction_languages = text_extraction_languages
      super
    end

    attr_reader :text_extraction_languages

    # Start text extraction for a single object
    class JobItem < BaseJobItem
      delegate :text_extraction_languages, to: :job

      def perform
        return unless check_update_ability?

        return failure!(message: 'Text extraction is not possible for this object') unless text_extraction.possible?

        return failure!(message: 'Object is currently assembling') if Sdr::VersionService.assembling?(druid:)

        text_extraction.start

        success!(message: "#{text_extraction.wf_name} successfully started")
      end

      private

      def text_extraction
        @text_extraction ||= Sdr::TextExtraction.new(cocina_object, languages: text_extraction_languages,
                                                                    already_opened: Sdr::VersionService.open?(druid:))
      end
    end
  end
end
