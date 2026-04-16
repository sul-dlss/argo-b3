# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Show::WorkflowAccordionItemComponent, type: :component do
  let(:component) { described_class.new(workflow:) }

  let(:workflow) { instance_double(Dor::Services::Response::Workflow, workflow_name: 'accessionWF', complete?: complete, processes:) }
  let(:version_two_process) do
    instance_double(Dor::Services::Response::Process,
                    name: 'accessioning-init',
                    version: 2,
                    lifecycle: 'accessioning',
                    status: 'completed',
                    datetime: nil,
                    elapsed: nil,
                    error_message: nil,
                    note: nil)
  end
  let(:version_one_process) do
    instance_double(Dor::Services::Response::Process,
                    name: 'shelve',
                    version: 1,
                    lifecycle: 'accessioning',
                    status: 'error',
                    datetime: nil,
                    elapsed: nil,
                    error_message: 'Something went wrong',
                    note: 'Retry queued')
  end
  let(:processes) { [version_one_process, version_two_process] }

  context 'when the workflow is incomplete' do
    let(:complete) { false }

    it 'renders an expanded accordion item with grouped workflow tables' do
      render_inline(component)

      expect(page).to have_css('div.accordion-item')
      expect(page).to have_css('h2.accordion-header button.accordion-button', text: 'accessionWF')
      expect(page).to have_css('button[data-bs-target="#accessionwf-collapse"][aria-controls="accessionwf-collapse"]' \
                               '[aria-expanded="true"]')
      expect(page).to have_css('span.badge', text: 'In progress')
      expect(page).to have_css('div#accessionwf-collapse.accordion-collapse.collapse.show')
      expect(page).to have_css('table#accessionwf-2-table caption', text: 'accessionWF - Version 2')
      expect(page).to have_css('table#accessionwf-1-table caption', text: 'accessionWF - Version 1')
      expect(page).to have_css('td.text-danger', text: 'Error: Something went wrong')
      expect(page).to have_css('td.text-success-emphasis', text: 'Note: Retry queued')

      expect(rendered_content.index('accessionWF - Version 2'))
        .to be < rendered_content.index('accessionWF - Version 1')
    end
  end

  context 'when the workflow is complete' do
    let(:complete) { true }

    it 'renders a collapsed accordion item with a complete badge' do
      render_inline(component)

      expect(page).to have_css('h2.accordion-header button.accordion-button.collapsed', text: 'accessionWF')
      expect(page).to have_css('button[data-bs-target="#accessionwf-collapse"][aria-controls="accessionwf-collapse"]' \
                               '[aria-expanded="false"]')
      expect(page).to have_css('span.badge', text: 'Complete')
      expect(page).to have_css('div#accessionwf-collapse.accordion-collapse.collapse')
      expect(page).to have_no_css('div#accessionwf-collapse.show')
    end
  end
end
