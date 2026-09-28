# frozen_string_literal: true

module Search
  # Parses the composite "<label>:<id>" values written by DSA's Indexing::CompositeFacetValue
  # into the two parts consumers need: the id (used for filtering/identity) and the label
  # (used for display). The id is either a druid (e.g., for APOs and Collections) or a URI (e.g., for licenses).
  # See https://github.com/sul-dlss/argo-b3/issues/530
  # DSA now indexes into composite fields with changes here: https://github.com/sul-dlss/dor-services-app/pull/6324
  class CompositeFacetValue
    # this regex is designed to work fine even if the title contains a colon somewhere in it
    DRUID_PATTERN = /\A(?<label>.*):(?<id>druid:[b-df-hjkmnp-tv-z]{2}\d{3}[b-df-hjkmnp-tv-z]{2}\d{4})\z/

    # The label is matched lazily so that the id starts at the first colon followed by a URI scheme.
    # Since URIs contain colons, this allows for a label that is itself a URI (as for unmapped licenses),
    # e.g., "https://example.com/license:https://example.com/license", and a URI that contains a port.
    URI_PATTERN = %r{\A(?<label>.*?):(?<id>[a-z][a-z0-9+.-]*://.+)\z}i

    # @param value [String] a composite facet value, e.g. "Stanford Theses:druid:bc123df4567" or
    #   "CC Zero 1.0:https://creativecommons.org/publicdomain/zero/1.0/legalcode"
    # @return [Array(String, String)] the [id, label] pair.
    #   Falls back to [value, value] if the value doesn't match the expected format.
    def self.parse(value)
      match = DRUID_PATTERN.match(value) || URI_PATTERN.match(value)
      return [value, value] unless match

      [match[:id], match[:label]]
    end
  end
end
