# frozen_string_literal: true

# Mime types of files in SDR.
module MimeTypes
  IMAGE_PREFIX = 'image/'

  GIF = 'image/gif'
  JP2 = 'image/jp2'
  JPEG = 'image/jpeg'
  PNG = 'image/png'
  TIFF = 'image/tiff'

  JSON = 'application/json'
  OCTET_STREAM = 'application/octet-stream'
  PDF = 'application/pdf'
  XHTML = 'application/xhtml+xml'
  XML = 'application/xml'
  ZIP = 'application/zip'

  HTML = 'text/html'
  PLAIN_TEXT = 'text/plain'
  TEXT_XML = 'text/xml'
  VTT = 'text/vtt'

  MP3 = 'audio/mpeg'
  MP4_AUDIO = 'audio/mp4'
  WAV = 'audio/wav'
  X_WAV = 'audio/x-wav'

  MP4_VIDEO = 'video/mp4'
  MOV = 'video/quicktime'
  MKV = 'video/x-matroska'

  GLTF_BINARY = 'model/gltf-binary'

  # Ordered from most to least common in SDR.
  COMMON = [
    XML,
    OCTET_STREAM,
    ZIP,
    JP2,
    TIFF,
    PDF,
    JPEG,
    PLAIN_TEXT,
    MP4_AUDIO,
    X_WAV,
    JSON,
    MP4_VIDEO,
    'application/vnd.shp',
    'application/vnd.dbf',
    'application/vnd.shx',
    'application/vnd.pmtiles',
    'application/vnd.fgb',
    MOV,
    'image/tiff; application=geotiff',
    'image/tiff; application=geotiff; profile=cloud-optimized',
    MP3,
    'image/x-nikon-nef',
    'image/x-raw',
    GIF,
    'video/mpeg',
    'application/msword',
    MKV,
    VTT,
    'application/mxf'
  ].freeze
end
