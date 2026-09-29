# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CatalogRepository do
  let(:catalog_record_id) { 'a12345' }

  describe '.exists?' do
    subject(:exists) { described_class.exists?(catalog_record_id:, **args) }

    let(:args) { {} }

    context 'when the catalog record exists' do
      before do
        allow(FolioClient).to receive(:fetch_instance_info).and_return({ 'id' => '123' })
      end

      it 'returns true' do
        expect(exists).to be true
        expect(FolioClient).to have_received(:fetch_instance_info).with(hrid: catalog_record_id)
      end
    end

    context 'when the catalog record is not found' do
      before do
        allow(FolioClient).to receive(:fetch_instance_info).and_raise(FolioClient::ResourceNotFound)
      end

      it 'returns false' do
        expect(exists).to be false
      end
    end

    context 'when the catalog record id matches multiple records' do
      before do
        allow(FolioClient).to receive(:fetch_instance_info).and_raise(FolioClient::MultipleResourcesFound)
      end

      it 'returns false' do
        expect(exists).to be false
      end
    end

    context 'when the catalog request fails' do
      before do
        allow(FolioClient).to receive(:fetch_instance_info).and_raise(FolioClient::ServiceUnavailable, 'Folio is down')
      end

      it 'raises an error wrapping the catalog error' do
        expect { exists }.to raise_error(described_class::Error, 'Folio is down')
      end

      context 'when catalog errors are allowed' do
        let(:args) { { allow_catalog_errors: true } }

        it 'returns true' do
          expect(exists).to be true
        end
      end
    end
  end

  describe '.title' do
    subject(:title) { described_class.title(catalog_record_id:) }

    context 'when the catalog record exists' do
      before do
        allow(FolioClient).to receive(:fetch_instance_info).and_return({ 'id' => '123', 'title' => 'The Title' })
      end

      it 'returns the title' do
        expect(title).to eq('The Title')
        expect(FolioClient).to have_received(:fetch_instance_info).with(hrid: catalog_record_id)
      end
    end

    context 'when the catalog record is not found' do
      before do
        allow(FolioClient).to receive(:fetch_instance_info).and_raise(FolioClient::ResourceNotFound)
      end

      it 'returns nil' do
        expect(title).to be_nil
      end
    end

    context 'when the catalog record id matches multiple records' do
      before do
        allow(FolioClient).to receive(:fetch_instance_info).and_raise(FolioClient::MultipleResourcesFound)
      end

      it 'returns nil' do
        expect(title).to be_nil
      end
    end

    context 'when the catalog request fails' do
      before do
        allow(FolioClient).to receive(:fetch_instance_info).and_raise(FolioClient::ServiceUnavailable, 'Folio is down')
      end

      it 'raises an error wrapping the catalog error' do
        expect { title }.to raise_error(described_class::Error, 'Folio is down')
      end
    end
  end
end
