# Helper methods for supporting caching
class CacheSupport
  # @return [Hash] hash for cocina object with blanks removed
  def self.cacheable_cocina_object(cocina_object:)
    CocinaDisplay::Utils.deep_compact_blank(cocina_object.to_h, preserve_keys: [:label])
  end
end
