# frozen_string_literal: true

require 'rails_helper'

RSpec.describe WorkflowGrid::WorkflowTableComponent, type: :component do
  let(:component) do
    described_class.new(workflow_name:, template: ACCESSIONWF_TEMPLATE, workflow_process_counts:, search_form:)
  end

  let(:workflow_name) { 'accessionWF' }
  let(:workflow_process_counts) { nil }
  let(:search_form) { SearchForm.new }

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

  let(:empty_solr_response) do
    {
      'facets' => {
        'wf_hierarchical_wps_ssimdv' => {
          'buckets' => [
            { 'val' => '3|accessionWF:start-accession:completed|-', 'count' => 0 },
            { 'val' => '3|accessionWF:shelve:completed|-', 'count' => 0 },
            { 'val' => '3|accessionWF:shelve:waiting|-', 'count' => 0 },
            { 'val' => '3|accessionWF:shelve:error|-', 'count' => 0 },
            { 'val' => '3|accessionWF:shelve:skipped|-', 'count' => 0 }
          ]
        }
      }
    }
  end

  context 'when workflow_process_counts is nil' do
    it 'renders placeholders' do
      render_inline(component)

      table = page.find('table.table-data#workflow-table-accessionWF')
      expect(table).to have_css('caption', text: 'accessionWF')
      expect(table).to have_link('accessionWF', href: '/search?wps_workflows%5B%5D=accessionWF')
      first_row = table.find('tbody tr:first-child')
      expect(first_row).to have_css('th', text: /1\..+start-accession/m)
      expect(page).to have_link('start-accession', href: '/search?wps_workflows%5B%5D=accessionWF%3Astart-accession')
      cells = first_row.all('td')
      expect(cells[0]).to have_text('Start Accessioning')
      expect(cells[1..4]).to all(have_css('span.placeholder'))
    end
  end

  context 'when workflow_process_counts is provided' do
    let(:workflow_process_counts) do
      SearchResults::WorkflowProcessCounts.new(solr_response:)
    end

    it 'renders the process counts' do
      render_inline(component)

      table = page.find('table.table-data#workflow-table-accessionWF')
      expect(table).to have_css('caption', text: 'accessionWF')
      row = table.find('tbody tr:nth-child(4)')
      expect(row).to have_css('th', text: /4\..+shelve/m)
      cells = row.all('td')
      expect(cells[0]).to have_text('Shelve content in Digital Stacks')
      expect(cells[1]).to have_text('4')
      expect(cells[1]).to have_link('4',
                                    href: '/search?wps_workflows%5B%5D=accessionWF%3Ashelve%3Awaiting')
      expect(cells[2]).to have_text('0')
      expect(cells[2]).to have_no_link('0')
      expect(cells[3]).to have_text('2')
      expect(cells[4]).to have_text('4,717,940')
    end
  end

  context 'when empty workflow_process_counts is provided' do
    let(:workflow_process_counts) do
      SearchResults::WorkflowProcessCounts.new(solr_response: empty_solr_response)
    end

    it 'does not render' do
      expect(component.render?).to be false
    end
  end
end
