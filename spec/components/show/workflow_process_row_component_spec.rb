# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Show::WorkflowProcessRowComponent, type: :component do
  let(:component) { described_class.new(process:) }

  # Rendered within a table since rows outside of a table are dropped when parsed.
  def render_row
    render_in_view_context(component) { |row_component| tag.table(tag.tbody(render(row_component))) }
  end

  context 'when the process completed' do
    let(:process) do
      instance_double(Dor::Services::Response::Process,
                      name: 'accessioning-init',
                      lifecycle: 'accessioning',
                      status: 'completed',
                      datetime: '2026-04-16T10:00:00Z',
                      elapsed: '90',
                      error_message: nil,
                      note: nil)
    end

    it 'renders the process row' do
      render_row

      expect(page).to have_css('tr th', text: 'accessioning-init')
      expect(page).to have_css('tr td', text: 'accessioning')
      expect(page).to have_css('tr td', text: 'Completed')
      expect(page).to have_no_css('.text-danger')
      expect(page).to have_no_css('li')
      expect(page).to have_css('tr td', text: '2026-04-16 03:00:00 PT')
      expect(page).to have_css('tr td', text: '2 minutes')
    end
  end

  context 'when the process errored with a note' do
    let(:process) do
      instance_double(Dor::Services::Response::Process,
                      name: 'shelve',
                      lifecycle: nil,
                      status: 'error',
                      datetime: nil,
                      elapsed: nil,
                      error_message: 'Something went wrong',
                      note: 'Retry queued')
    end

    it 'renders the error status, error message, and note' do
      render_row

      expect(page).to have_css('tr td span.text-danger i.bi-exclamation-triangle-fill')
      expect(page).to have_css('tr td span.text-danger', text: 'Error')
      expect(page).to have_css('tr td li span.text-danger', text: 'Something went wrong')
      expect(page).to have_css('tr td li', text: 'Note: Retry queued')
    end
  end
end
