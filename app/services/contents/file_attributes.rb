# frozen_string_literal: true

module Contents
  # Determines the default preserve / shelve / publish flags and role for a file from its mime type.
  # Ported from pre-assembly's PreAssembly::FromStagingLocation::File.
  class FileAttributes
    # A file with an unmapped mime type is preserved only.
    DEFAULT = { preserve: true, shelve: false, publish: false, use: nil }.freeze

    # Overrides the flags (but not the use) for a file that is preserved only.
    DARK = { preserve: true, shelve: false, publish: false }.freeze

    # Attributes for a file that is not accompanied by OCR.
    ATTRIBUTES_FOR_MIME_TYPE = {
      MimeTypes::TIFF => { preserve: true, shelve: false, publish: false },
      MimeTypes::JP2 => { preserve: false, shelve: true, publish: true },
      MimeTypes::JPEG => { preserve: true, shelve: false, publish: false },
      MimeTypes::PNG => { preserve: true, shelve: false, publish: false },
      MimeTypes::WAV => { preserve: true, shelve: false, publish: false },
      MimeTypes::X_WAV => { preserve: true, shelve: false, publish: false },
      MimeTypes::PDF => { preserve: true, shelve: true, publish: true },
      MimeTypes::PLAIN_TEXT => { preserve: true, shelve: true, publish: true },
      MimeTypes::ZIP => { preserve: true, shelve: false, publish: false },
      MimeTypes::JSON => { preserve: true, shelve: true, publish: true },
      MimeTypes::HTML => { preserve: true, shelve: true, publish: true },
      MimeTypes::GLTF_BINARY => { preserve: true, shelve: true, publish: true }
    }.freeze

    # Attributes for a file that is accompanied by OCR. Note that application/xml is only present here,
    # since an XML file that does not accompany an image is some other sort of metadata.
    ATTRIBUTES_FOR_MIME_TYPE_WITH_OCR = {
      MimeTypes::TIFF => { preserve: true, shelve: false, publish: false },
      MimeTypes::JP2 => { preserve: true, shelve: true, publish: true },
      MimeTypes::JPEG => { preserve: true, shelve: false, publish: false },
      MimeTypes::PNG => { preserve: true, shelve: false, publish: false },
      MimeTypes::PDF => { preserve: true, shelve: true, publish: true, use: 'transcription' },
      MimeTypes::PLAIN_TEXT => { preserve: true, shelve: true, publish: true, use: 'transcription' },
      MimeTypes::HTML => { preserve: true, shelve: true, publish: true, use: 'transcription' },
      MimeTypes::XML => { preserve: true, shelve: true, publish: true, use: 'transcription' }
    }.freeze

    # Attributes for a file that accompanies an image, when not overridden by the attributes with OCR.
    ATTRIBUTES_FOR_MIME_TYPE_WITH_IMAGE = {
      MimeTypes::JSON => { preserve: true, shelve: true, publish: true, use: 'annotations' }
    }.freeze

    def self.call(...)
      new(...).call
    end

    # @param [String,nil] mime_type the mime type of the file
    # @param [Boolean] dark when true, the file is preserved only
    # @param [Boolean] ocr when true, the file is part of a file set that contains OCR
    # @param [Boolean] with_image when true, the file is part of a file set that contains an image
    def initialize(mime_type:, dark:, ocr: false, with_image: false)
      @mime_type = mime_type
      @ocr = ocr
      @with_image = with_image
      @dark = dark
    end

    # @return [Hash] the preserve, shelve, publish, and use attributes for the file
    def call
      attributes = DEFAULT.merge(attributes_for_mime_type)
      return attributes.merge(DARK) if dark

      attributes
    end

    private

    attr_reader :mime_type, :ocr, :with_image, :dark

    def attributes_for_mime_type
      return ATTRIBUTES_FOR_MIME_TYPE_WITH_OCR.fetch(mime_type) if ocr &&
                                                                   ATTRIBUTES_FOR_MIME_TYPE_WITH_OCR.key?(mime_type)
      return ATTRIBUTES_FOR_MIME_TYPE_WITH_IMAGE.fetch(mime_type) if with_image &&
                                                                     ATTRIBUTES_FOR_MIME_TYPE_WITH_IMAGE.key?(mime_type)

      ATTRIBUTES_FOR_MIME_TYPE.fetch(mime_type, DEFAULT)
    end
  end
end
