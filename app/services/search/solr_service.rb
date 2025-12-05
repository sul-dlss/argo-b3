# frozen_string_literal: true

module Search
  # Service for querying Solr
  class SolrService
    def self.post(request:)
      solr = Search::SolrFactory.call
      # This is necessary for csv wt.
      params = { wt: request[:wt] }.compact
      solr.post('select', data: request, params:)
    end

    def self.stream(request:, stream:, replacement_header: nil)
      first_chunk = true
      # Need the raw Faraday connection.
      connection = Search::SolrFactory.call.connection
      connection.post('select') do |req|
        req.headers['Content-Type'] = 'application/x-www-form-urlencoded; charset=UTF-8'
        req.body = RSolr::Uri.params_to_solr request
        req.options.on_data = proc do |chunk|
          if first_chunk
            first_chunk = false
            # Replace the header row (which comes back from solr with field names) and replace with field labels.
            chunk.sub!(/^.*?\n/m, replacement_header) if replacement_header
          end
          stream.write chunk
        end
      end
    ensure
      stream.close
    end
  end
end
