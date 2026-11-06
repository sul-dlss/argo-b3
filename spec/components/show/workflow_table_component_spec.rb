# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Show::WorkflowTableComponent, type: :component do
  let(:component) { described_class.new(workflow:, version: 2, processes:, solr_doc:) }
  let(:solr_doc) { SolrDocPresenter.new(solr_doc: { Search::Fields::ID => 'druid:bc123df4567' }) }
  let(:active_version) { true }
  let(:workflow) { instance_double(Dor::Services::Response::Workflow, workflow_name: 'accessionWF') }
  let(:first_process) do
    instance_double(Dor::Services::Response::Process,
                    name: 'accessioning-init',
                    lifecycle: 'accessioning',
                    status: 'completed',
                    datetime: '2026-04-16T10:00:00Z',
                    elapsed: '90',
                    error_message: nil,
                    note: nil,
                    active_version?: active_version)
  end
  let(:second_process) do
    instance_double(Dor::Services::Response::Process,
                    name: 'shelve',
                    workflow_name: 'accessionWF',
                    version: 2,
                    lifecycle: 'accessioning',
                    status: 'error',
                    datetime: nil,
                    elapsed: nil,
                    error_message: 'Something went wrong',
                    note: 'Retry queued',
                    active_version?: active_version)
  end
  let(:processes) { [first_process, second_process] }

  before do
    allow(Current).to receive(:user).and_return(create(:user))
  end

  it 'renders the workflow table with a row for each process and actions for the process in error' do
    render_inline(component)

    expect(page).to have_table(id: 'accessionwf-2-table')
    expect(page).to have_css('table caption', text: 'accessionWF - Version 2')
    expect(page).to have_css('th', text: 'Process')
    expect(page).to have_css('th', text: 'Lifecycle')
    expect(page).to have_css('th', text: 'Status')
    expect(page).to have_css('th', text: 'Note')
    expect(page).to have_css('th', text: 'When')
    expect(page).to have_css('th', text: 'Elapsed')
    expect(page).to have_css('thead th:last-child', text: 'Actions')
    expect(page).to have_css('tbody tr th', text: 'accessioning-init')
    expect(page).to have_css('tbody tr th', text: 'shelve')
    expect(page).to have_css('tbody tr:nth-of-type(2) td:last-child button', text: 'Retry')
    expect(page).to have_no_css('tbody tr:nth-of-type(1) button')
  end

  context 'when the version is not the active version' do
    let(:active_version) { false }

    it 'renders the workflow table without actions' do
      render_inline(component)

      expect(page).to have_no_css('th', text: 'Actions')
      expect(page).to have_no_button('Retry')
    end
  end
end
