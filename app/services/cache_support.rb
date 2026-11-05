# frozen_string_literal: true

# Helper methods for supporting caching
class CacheSupport
  # @return [Hash] hash for cocina object with blanks removed
  def self.cacheable_cocina_object(cocina_object:)
    CocinaDisplay::Utils.deep_compact_blank(cocina_object.to_h, preserve_keys: [:label])
  end

  # @return [String] cache key for the object's live solr doc, as used by the show page
  def self.solr_doc_cache_key(druid:)
    "objects/solr-doc/#{druid}"
  end
end
