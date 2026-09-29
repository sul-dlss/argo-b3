# frozen_string_literal: true

# Helper methods for working with URIs
class UriSupport
  # Provides a short, human-readable name for a URI, e.g., for use as a label.
  # @param uri [String] a URI, e.g., https://cocina.sul.stanford.edu/models/book
  # @return [String] the last segment of the URI's path, e.g., book
  def self.last(uri:)
    uri.split('/').last
  end
end
