# frozen_string_literal: true

module Edit
  # Component for selecting the MIME type of a file.
  # The user can select a common MIME type or enter another one.
  class MimeTypeComponent < ApplicationComponent
    # Ordered from most to least common in SDR.
    MIME_TYPES = [
      'application/xml',
      'application/octet-stream',
      'application/zip',
      'image/jp2',
      'image/tiff',
      'application/pdf',
      'image/jpeg',
      'text/plain',
      'audio/mp4',
      'audio/x-wav',
      'application/json',
      'video/mp4',
      'application/vnd.shp',
      'application/vnd.dbf',
      'application/vnd.shx',
      'application/vnd.pmtiles',
      'application/vnd.fgb',
      'video/quicktime',
      'image/tiff; application=geotiff',
      'image/tiff; application=geotiff; profile=cloud-optimized',
      'audio/mpeg',
      'image/x-nikon-nef',
      'image/x-raw',
      'image/gif',
      'video/mpeg',
      'application/msword',
      'video/x-matroska',
      'text/vtt',
      'application/mxf'
    ].freeze

    # @param form [ActionView::Helpers::FormBuilder] a nested form builder for a ContentFileForm
    def initialize(form:)
      @form = form
      super()
    end

    attr_reader :form

    # Includes the current MIME type when it is not a common one, so that it remains selected.
    def options
      mime_type = form.object.mime_type
      return MIME_TYPES if mime_type.blank? || MIME_TYPES.include?(mime_type)

      [mime_type, *MIME_TYPES]
    end
  end
end
