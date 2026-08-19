# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ObjectStatusPresenter do
  subject(:presenter) { described_class.new(document:, version_service:, content:) }

  let(:document) { SolrDocPresenter.new(solr_doc: build(:solr_item, druid:, workflow_errors:)) }
  let(:druid) { 'druid:bc123df4567' }
  let(:workflow_errors) { [] }

  let(:version_service) do
    instance_double(Sdr::VersionService, accessioning?: accessioning, closed?: closed)
  end
  let(:closed) { false }
  let(:accessioning) { false }
  let(:content) { nil }

  describe '#status' do
    context 'when the version is open' do
      it 'returns draft' do
        expect(presenter.status).to eq(:draft)
      end
    end

    context 'when the content is staging' do
      let(:content) { build(:content, staging_state: 'staging') }

      it 'returns staging' do
        expect(presenter.status).to eq(:staging)
      end
    end

    context 'when the content is staging and there are workflow errors' do
      let(:content) { build(:content, staging_state: 'staging') }
      let(:workflow_errors) { ['accessionWF:end-accession:Object cannot be OCRd'] }

      it 'returns staging' do
        expect(presenter.status).to eq(:staging)
      end
    end

    context 'when the version is closed and not accessioning' do
      let(:closed) { true }

      it 'returns deposited' do
        expect(presenter.status).to eq(:deposited)
      end
    end

    context 'when the version is accessioning' do
      let(:closed) { true }
      let(:accessioning) { true }

      it 'returns depositing' do
        expect(presenter.status).to eq(:depositing)
      end
    end

    context 'when there are workflow errors' do
      let(:workflow_errors) { ['accessionWF:end-accession:Object cannot be OCRd'] }

      it 'returns error' do
        expect(presenter.status).to eq(:error)
      end
    end

    context 'when there are workflow errors while the version is still accessioning' do
      let(:closed) { true }
      let(:accessioning) { true }
      let(:workflow_errors) { ['accessionWF:end-accession:Object cannot be OCRd'] }

      it 'returns error' do
        expect(presenter.status).to eq(:error)
      end
    end
  end

  describe '#workflow_error_messages' do
    let(:workflow_errors) { ['accessionWF:end-accession:Object cannot be OCRd'] }

    it 'formats the workflow errors' do
      expect(presenter.workflow_error_messages).to eq(['end-accession : Object cannot be OCRd'])
    end
  end
end
