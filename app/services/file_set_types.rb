# frozen_string_literal: true

# Cocina FileSet (resource) types, without the URI prefix (as stored in ContentFileSet#file_set_type).
module FileSetTypes
  PREFIX = 'https://cocina.sul.stanford.edu/models/resources/'

  THREE_DIMENSIONAL = '3d'
  AUDIO = 'audio'
  DOCUMENT = 'document'
  FILE = 'file'
  IMAGE = 'image'
  MEDIA = 'media'
  OBJECT = 'object'
  PAGE = 'page'
  PREVIEW = 'preview'
  VIDEO = 'video'

  # Cocina types that are no longer used. This code can be removed if cocina-models fileset types are updated.
  UNUSED = %w[attachment thumb].freeze

  # All types allowed in Cocina, except unused types.
  ALL = (Cocina::Models::FileSet::TYPES.map { |uri| uri.delete_prefix(PREFIX) } - UNUSED).freeze

  # Type to Cocina URI.
  URIS = Cocina::Models::FileSet::TYPES.index_by { |uri| uri.delete_prefix(PREFIX) }.slice(*ALL).freeze

  # Type to Cocina URI, for types offered by the manage content type bulk action.
  BULK_ACTION_URIS = URIS.except(MEDIA, PREVIEW).freeze
end
