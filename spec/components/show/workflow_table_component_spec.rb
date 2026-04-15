# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Show::WorkflowTableComponent, type: :component do
  let(:component) { described_class.new(workflow:, version: 2, processes:) }
  let(:formatted_datetime) do
    I18n.l(Time.zone.parse(first_process.datetime).in_time_zone('Pacific Time (US & Canada)'), format: :long)
  end

  let(:workflow) { instance_double(Dor::Services::Response::Workflow, workflow_name: 'accessionWF') }
  let(:first_process) do
    instance_double(Dor::Services::Response::Process,
                    name: 'accessioning-init',
                    lifecycle: 'accessioning',
                    status: 'completed',
                    datetime: '2026-04-16T10:00:00Z',
                    elapsed: '90',
                    error_message: nil,
                    note: nil)
  end
  let(:second_process) do
    instance_double(Dor::Services::Response::Process,
                    name: 'shelve',
                    lifecycle: 'accessioning',
                    status: 'error',
                    datetime: nil,
                    elapsed: nil,
                    error_message: 'Something went wrong',
                    note: 'Retry queued')
  end
  let(:processes) { [first_process, second_process] }

  it 'renders the workflow table with process rows and details' do
    render_inline(component)

    expect(page).to have_table(id: 'accessionwf-2-table')
    expect(page).to have_css('table caption', text: 'accessionWF - Version 2')
    expect(page).to have_css('th', text: 'Process')
    expect(page).to have_css('th', text: 'Lifecycle')
    expect(page).to have_css('th', text: 'Status')
    expect(page).to have_css('th', text: 'When')
    expect(page).to have_css('th', text: 'Elapsed')
    expect(page).to have_css('tbody tr', text: 'accessioning-init')
    expect(page).to have_css('tbody tr', text: 'completed')
    expect(page).to have_text('April 16, 2026 03:00')
    expect(page).to have_text('2 minutes')
    expect(page).to have_css('td.text-danger', text: 'Error: Something went wrong')
    expect(page).to have_css('td.text-success-emphasis', text: 'Note: Retry queued')
  end
end
