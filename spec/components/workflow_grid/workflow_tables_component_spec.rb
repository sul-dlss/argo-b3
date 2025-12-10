# frozen_string_literal: true

require 'rails_helper'

RSpec.describe WorkflowGrid::WorkflowTablesComponent, type: :component do
  let(:component) { described_class.new(templates:, search_form:, scope: 'all', workflow_process_counts:) }

  let(:workflow_process_counts) { nil }
  let(:search_form) { SearchForm.new(query: 'test') }
  let(:templates) do
    {
      'accessionWF' => ACCESSIONWF_TEMPLATE
    }
  end

  context 'when rendering the placeholder variation' do
    it 'renders the placeholder workflow tables' do
      render_inline(component)

      expect(page).to have_css('turbo-frame#workflow-grid[src="/workflow_grid?placeholder=false&scope=all"]')
      expect(page).to have_css('turbo-frame table#workflow-table-accessionWF tbody td span.placeholder')
    end
  end

  context 'when rendering with workflow process counts' do
    let(:workflow_process_counts) { SearchResults::WorkflowProcessCounts.new(solr_response:) }

    let(:solr_response) do
      {
        'facets' => {
          'wf_hierarchical_wps_ssimdv' => {
            'buckets' => [
              { 'val' => '3|accessionWF:start-accession:completed|-', 'count' => 4_717_947 },
              { 'val' => '3|accessionWF:shelve:completed|-', 'count' => 4_717_940 },
              { 'val' => '3|accessionWF:shelve:waiting|-', 'count' => 4 },
              { 'val' => '3|accessionWF:shelve:error|-', 'count' => 2 },
              { 'val' => '3|accessionWF:shelve:skipped|-', 'count' => 1 }
            ]
          }
        }
      }
    end

    it 'renders the placeholder workflow tables' do
      render_inline(component)

      expect(page).to have_css('turbo-frame#workflow-grid:not([src])')
      expect(page)
        .to have_css('turbo-frame table#workflow-table-accessionWF tbody td', text: '4,717,947')
    end
  end
end
