# frozen_string_literal: true

module Search
  # Parses the composite "<label>:<druid>" values written by DSA's Indexing::CompositeFacetValue
  # into the two parts consumers need: the druid (used for filtering/identity) and the label
  # (used for display). See https://github.com/sul-dlss/argo-b3/issues/530
  # DSA now indexes into composite fields with changes here: https://github.com/sul-dlss/dor-services-app/pull/6324
  class CompositeFacetValue
    # this regex is designed to work fine even if the title contains a colon somewhere in it
    PATTERN = /\A(?<label>.*):(?<druid>druid:[b-df-hjkmnp-tv-z]{2}\d{3}[b-df-hjkmnp-tv-z]{2}\d{4})\z/

    # @param value [String] a composite facet value, e.g. "Stanford Theses:druid:bc123df4567"
    # @return [Array(String, String)] the [druid, label] pair.
    #   Falls back to [value, value] if the value doesn't match the expected format.
    def self.parse(value)
      match = PATTERN.match(value)
      return [value, value] unless match

      [match[:druid], match[:label]]
    end
  end
end
