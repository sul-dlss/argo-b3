# frozen_string_literal: true

module Sdr
  # Start the OCR text extraction workflow for a given object
  class TextExtraction
    WORKFLOW_NAME = 'ocrWF'
    SUPPORTED_TYPES = [
      Cocina::Models::ObjectType.book,
      Cocina::Models::ObjectType.document,
      Cocina::Models::ObjectType.image
    ].freeze

    attr_reader :cocina_object, :languages, :already_opened

    # @param [Cocina::Models::DRO] cocina_object the object to start text extraction for
    # @param [Boolean] already_opened whether the object has already been opened
    # @param [Array<String>] languages the languages to extract text for, default to empty
    def initialize(cocina_object, already_opened:, languages: [])
      @cocina_object = cocina_object
      @languages = languages
      @already_opened = already_opened
    end

    # start the text extraction workflow for the object if possible
    def call
      return unless ocr_able?

      version = cocina_object.version
      # if the object has already been opened, don't increment the version for the new workflow
      # this is to ensure the new workflow is started with the same version as the existing object
      # if the object is already open, they are the same; if not, ocrWF will open the object version,
      # incrementing it
      version += 1 unless already_opened
      Dor::Services::Client.object(cocina_object.externalIdentifier)
                           .workflow(WORKFLOW_NAME)
                           .create(version:, lane_id: 'low', context:)
    end

    # ocrWF should only run when enabled and on DROs with supported object types
    def ocr_able?
      return false unless Settings.feature_flags.ocr_workflow

      cocina_object.dro? && SUPPORTED_TYPES.include?(cocina_object.type)
    end

    private

    # the workflow context to set
    def context
      { manuallyCorrectedOCR: false, ocrLanguages: languages }
    end
  end
end
