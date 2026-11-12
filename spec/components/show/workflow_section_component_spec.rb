# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Show::WorkflowSectionComponent, type: :component do
  let(:component) { described_class.new(workflow:, solr_doc:) }

  let(:solr_doc) { SolrDocPresenter.new(solr_doc: { Search::Fields::ID => 'druid:bc123df4567' }) }

  let(:workflow) do
    xml = <<~XML
      <workflow repository="dor" objectId="druid:bc123df4567" id="accessionWF">
        <process version="1" laneId="default" elapsed="0.0" lifecycle="accessioned" note="Retry queued"
                 errorMessage="Something went wrong" status="error" datetime="2024-01-01T10:00:00+00:00" name="shelve"/>
        <process version="2" laneId="default" elapsed="0.0" lifecycle="accessioning" status="completed"
                 datetime="2024-01-02T10:00:00+00:00" name="start-accession"/>
        #{latest_version_process}
      </workflow>
    XML
    Dor::Services::Response::Workflow.new(xml:)
  end

  context 'when the latest version has a process in error' do
    let(:latest_version_process) do
      '<process version="2" laneId="default" lifecycle="published" errorMessage="Publish failed" status="error" ' \
        'datetime="2024-01-02T11:00:00+00:00" name="publish"/>'
    end

    it 'renders an expanded section with an error indicator' do
      render_inline(component)

      expect(page).to have_css('h2.workflow-section-heading button.collapsible-section-toggle', text: 'accessionWF')
      expect(page).to have_css('button[aria-controls="accessionwf-collapse"][aria-expanded="true"]')
      expect(page).to have_css('button span.text-danger i.bi-exclamation-triangle-fill')
      expect(page).to have_css('button span.text-danger', text: 'Error')
      expect(page).to have_no_css('.collapsible-section-toggle', text: 'In progress')
      expect(page).to have_css('div#accessionwf-collapse.collapse.show')
    end
  end

  context 'when the workflow is in progress' do
    let(:latest_version_process) do
      '<process version="2" laneId="default" lifecycle="published" status="waiting" name="publish"/>'
    end

    it 'renders an expanded section with grouped workflow tables' do
      render_inline(component)

      expect(page).to have_css('section.workflow-section')
      expect(page).to have_css('h2.workflow-section-heading button.collapsible-section-toggle', text: 'accessionWF')
      expect(page).to have_css('button[data-bs-target="#accessionwf-collapse"][aria-controls="accessionwf-collapse"]' \
                               '[aria-expanded="true"]')
      expect(page).to have_css('button span.workflow-in-progress i.bi-clock-history')
      expect(page).to have_css('button span.workflow-in-progress', text: 'In progress')
      expect(page).to have_no_css('.collapsible-section-toggle', text: 'Error')
      expect(page).to have_css('div#accessionwf-collapse.collapse.show')
      expect(page).to have_css('table#accessionwf-2-table caption', text: 'accessionWF - Version 2')
      expect(page).to have_css('table#accessionwf-1-table caption', text: 'accessionWF - Version 1')
      expect(page).to have_css('table#accessionwf-1-table td span.text-danger', text: 'Something went wrong')

      expect(rendered_content.index('accessionWF - Version 2'))
        .to be < rendered_content.index('accessionWF - Version 1')
    end
  end

  context 'when the workflow is complete and only an older version has a process in error' do
    let(:latest_version_process) { '' }

    it 'renders a collapsed section with a complete indicator' do
      render_inline(component)

      expect(page).to have_css('h2.workflow-section-heading button.collapsible-section-toggle.collapsed',
                               text: 'accessionWF')
      expect(page).to have_css('button[data-bs-target="#accessionwf-collapse"][aria-controls="accessionwf-collapse"]' \
                               '[aria-expanded="false"]')
      expect(page).to have_css('button span.text-success i.bi-check-circle-fill')
      expect(page).to have_css('button span.text-success', text: 'Complete')
      expect(page).to have_no_css('.collapsible-section-toggle', text: 'Error')
      expect(page).to have_css('div#accessionwf-collapse.collapse')
      expect(page).to have_no_css('div#accessionwf-collapse.show')
    end
  end
end
