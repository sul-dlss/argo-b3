# frozen_string_literal: true

def reset_solr!
  solr = Search::SolrFactory.call
  solr.delete_by_query('*:*')
  solr.commit
end

# Resets solr before and after when configured with :solr
RSpec.configure do |config|
  config.around(:example, :solr) do |example|
    reset_solr!
    example.run
    reset_solr!
  end
end
