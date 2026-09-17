# frozen_string_literal: true

# Search form for the search results view.
#
# In addition to the query attributes inherited from SearchForm, this adds the attributes that
# control how matching objects are presented as a list.
class ResultsSearchForm < SearchForm
  DEFAULT_PAGE = 1

  attribute :page, :integer, default: DEFAULT_PAGE
  attribute :sort, :string

  def self.non_query_attributes
    super + %w[page sort]
  end

  # Drops the default page so that it is not included in URLs, in the same way that the base class
  # drops blank values. Without this, every generated link would carry page=1.
  def attributes
    super_attributes = super
    return super_attributes unless super_attributes['page'] == DEFAULT_PAGE

    super_attributes.except('page')
  end

  def self.route_scope
    'search'
  end

  def pinnable?
    true
  end

  def sortable?
    true
  end

  def item_results?
    true
  end
end
