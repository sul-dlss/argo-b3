# frozen_string_literal: true

# Search results for Boolean expressions entered on the advanced search page.
class AdvancedSearchForm < ResultsSearchForm
  def self.route_scope
    'advanced_search'
  end

  # The server's minimum-should-match default would require both sides of a short OR query.
  def solr_query_parameters
    { defType: 'edismax', mm: '0%', 'q.op': 'AND' }
  end

  def pinnable?
    false
  end

  def advanced?
    true
  end
end
