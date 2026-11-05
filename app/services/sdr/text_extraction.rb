# frozen_string_literal: true

module Sdr
  # Start the text extraction workflow for a given object: OCR (ocrWF) or speech to text (speechToTextWF),
  # depending on the object's content type.
  class TextExtraction
    OCR_WORKFLOW_NAME = 'ocrWF'
    SPEECH_TO_TEXT_WORKFLOW_NAME = 'speechToTextWF'
    OCR_TYPES = [
      Cocina::Models::ObjectType.book,
      Cocina::Models::ObjectType.document,
      Cocina::Models::ObjectType.image
    ].freeze
    SPEECH_TO_TEXT_TYPES = [Cocina::Models::ObjectType.media].freeze

    # @return [Array<String>] the content types that speech to text can run on; none unless the feature is enabled
    def self.speech_to_text_types
      Settings.feature_flags.speech_to_text_workflow ? SPEECH_TO_TEXT_TYPES : []
    end

    # @param [String] content_type the cocina type URI
    def self.ocr_type?(content_type)
      OCR_TYPES.include?(content_type)
    end

    # @param [String] content_type the cocina type URI
    def self.speech_to_text_type?(content_type)
      speech_to_text_types.include?(content_type)
    end

    # @param [String] content_type the cocina type URI
    # @return [String, nil] the text extraction workflow for the content type, if any
    def self.workflow_name_for(content_type)
      return OCR_WORKFLOW_NAME if ocr_type?(content_type)

      SPEECH_TO_TEXT_WORKFLOW_NAME if speech_to_text_type?(content_type)
    end

    attr_reader :cocina_object, :languages, :already_opened

    # @param [Cocina::Models::DRO] cocina_object the object to start text extraction for
    # @param [Boolean] already_opened whether the object has already been opened
    # @param [Array<String>] languages the languages to extract text for (OCR only), default to empty
    def initialize(cocina_object, already_opened:, languages: [])
      @cocina_object = cocina_object
      @languages = languages
      @already_opened = already_opened
    end

    # start the text extraction workflow for the object if possible
    def call
      return unless possible?

      version = cocina_object.version
      # if the object has already been opened, don't increment the version for the new workflow
      # this is to ensure the new workflow is started with the same version as the existing object
      # if the object is already open, they are the same; if not, ocrWF/speechToTextWF will open the object version,
      # incrementing it
      version += 1 unless already_opened
      Dor::Services::Client.object(cocina_object.externalIdentifier)
                           .workflow(workflow_name)
                           .create(version:, lane_id: 'low', context:)
    end

    # text extraction should only run on DROs with a content type that has a text extraction workflow
    def possible?
      cocina_object.dro? && workflow_name.present?
    end

    # @return [String, nil] the workflow to start
    def workflow_name
      self.class.workflow_name_for(cocina_object.type)
    end

    private

    # the workflow context to set
    def context
      return {} if workflow_name == SPEECH_TO_TEXT_WORKFLOW_NAME

      { manuallyCorrectedOCR: false, ocrLanguages: languages }
    end
  end
end
