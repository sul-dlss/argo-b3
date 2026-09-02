# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Show::StatusComponent, type: :component do
  subject(:component) { described_class.new(object_status_presenter:, druid:) }

  let(:object_status_presenter) { ObjectStatusPresenter.new(document:, version_service:, content:) }
  let(:document) { SolrDocPresenter.new(solr_doc: build(:solr_item, druid:, workflow_errors:)) }
  let(:druid) { 'druid:bc123df4567' }
  let(:workflow_errors) { [] }

  let(:version_service) do
    instance_double(Sdr::VersionService, accessioning?: accessioning, closed?: closed)
  end
  let(:closed) { false }
  let(:accessioning) { false }
  let(:content) { nil }

  context 'when the version is open' do
    it 'renders the draft status' do
      render_inline(component)

      expect(page).to have_css('h2', text: 'Draft, not deposited')
      expect(page).to have_button('Edit item', class: 'btn btn-outline-primary btn-sm disabled')
      expect(page).to have_link('Manage files', href: "/contents/#{druid}/edit",
                                                class: 'btn btn-outline-primary btn-sm')
      expect(page).to have_button('Deposit', class: 'btn btn-primary btn-sm disabled')
    end
  end

  context 'when the version is closed and not accessioning' do
    let(:closed) { true }

    it 'renders the deposited status' do
      render_inline(component)

      expect(page).to have_css('h2', text: 'Deposited')
      expect(page).to have_css('h2 i.bi-check-circle-fill')
      expect(page).to have_button('Edit item', class: 'btn btn-outline-primary btn-sm disabled')
      expect(page).to have_link('Manage files', href: "/contents/#{druid}/edit",
                                                class: 'btn btn-outline-primary btn-sm')
      expect(page).to have_no_button('Deposit')
    end
  end

  context 'when the version is accessioning' do
    let(:closed) { true }
    let(:accessioning) { true }

    it 'renders the depositing status' do
      render_inline(component)

      expect(page).to have_css('h2', text: 'Depositing...')
      expect(page).to have_text('Actions unavailable until deposit is complete.')
    end
  end

  context 'when there are workflow errors' do
    let(:workflow_errors) { ['accessionWF:end-accession:Object cannot be OCRd'] }

    it 'renders the error status with the parsed error message' do
      render_inline(component)

      expect(page).to have_css('h2', text: 'Error')
      expect(page).to have_css('h2 i.bi-exclamation-triangle-fill')
      expect(page).to have_text('end-accession : Object cannot be OCRd')
    end
  end

  context 'when there are workflow errors while the version is still accessioning' do
    let(:closed) { true }
    let(:accessioning) { true }
    let(:workflow_errors) { ['accessionWF:end-accession:Object cannot be OCRd'] }

    it 'renders the error status' do
      render_inline(component)

      expect(page).to have_css('h2', text: 'Error')
    end
  end

  context 'when the content is staging' do
    let(:content) { build(:content, staging_state: 'staging') }

    it 'renders the staging status' do
      render_inline(component)

      expect(page).to have_css('h2', text: 'Staging files')
    end
  end
end
