# frozen_string_literal: true

# Search form for the workflow grid (workflow status) view.
#
# The grid displays workflow process counts for the objects matching the search, so it needs no
# presentation attributes of its own: there is no paging or sorting.
class WorkflowGridSearchForm < SearchForm
  def self.route_scope
    'workflow_grid'
  end
end
