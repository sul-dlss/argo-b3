# frozen_string_literal: true

module Contents
  # Determines the default preserve / shelve / publish flags and role for a file from its mime type.
  # Ported from pre-assembly's PreAssembly::FromStagingLocation::File.
  class FileAttributes
    DEFAULT = { preserve: true, shelve: false, publish: false, use: nil }.freeze

    # Attributes for a file that is not accompanied by OCR.
    ATTRIBUTES_FOR_MIME_TYPE = {
      'image/tiff' => { preserve: true, shelve: false, publish: false },
      'image/jp2' => { preserve: false, shelve: true, publish: true },
      'image/jpeg' => { preserve: true, shelve: false, publish: false },
      'image/png' => { preserve: true, shelve: false, publish: false },
      'audio/wav' => { preserve: true, shelve: false, publish: false },
      'audio/x-wav' => { preserve: true, shelve: false, publish: false },
      'audio/mp3' => { preserve: false, shelve: true, publish: true },
      'audio/mpeg' => { preserve: false, shelve: true, publish: true },
      'application/pdf' => { preserve: true, shelve: true, publish: true },
      'text/plain' => { preserve: true, shelve: true, publish: true },
      'application/zip' => { preserve: true, shelve: false, publish: false },
      'application/json' => { preserve: true, shelve: true, publish: true }
    }.freeze

    # Attributes for a file that is accompanied by OCR. Note that application/xml is only present here,
    # since an XML file that does not accompany an image is some other sort of metadata.
    ATTRIBUTES_FOR_MIME_TYPE_WITH_OCR = {
      'image/tiff' => { preserve: true, shelve: false, publish: false },
      'image/jp2' => { preserve: true, shelve: true, publish: true },
      'image/jpeg' => { preserve: true, shelve: false, publish: false },
      'image/png' => { preserve: true, shelve: false, publish: false },
      'application/pdf' => { preserve: true, shelve: true, publish: true, use: 'transcription' },
      'text/plain' => { preserve: true, shelve: true, publish: true },
      'application/xml' => { preserve: true, shelve: true, publish: true, use: 'transcription' }
    }.freeze

    def self.call(...)
      new(...).call
    end

    # @param [String,nil] mime_type the mime type of the file
    # @param [Boolean] ocr when true, the file is part of a file set that contains OCR
    def initialize(mime_type:, ocr: false)
      @mime_type = mime_type
      @ocr = ocr
    end

    # @return [Hash] the preserve, shelve, publish, and use attributes for the file
    def call
      DEFAULT.merge(attributes_for_mime_type)
    end

    private

    attr_reader :mime_type, :ocr

    def attributes_for_mime_type
      return ATTRIBUTES_FOR_MIME_TYPE_WITH_OCR.fetch(mime_type) if ocr &&
                                                                   ATTRIBUTES_FOR_MIME_TYPE_WITH_OCR.key?(mime_type)

      ATTRIBUTES_FOR_MIME_TYPE.fetch(mime_type, DEFAULT)
    end
  end
end
