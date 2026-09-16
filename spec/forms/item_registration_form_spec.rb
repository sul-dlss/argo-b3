# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ItemRegistrationForm do
  before do
    allow(Sdr::Repository).to receive(:source_id_exists?).and_return(false)
  end

  describe '#empty?' do
    it 'is true when all attributes are blank' do
      expect(described_class.new.empty?).to be(true)
    end

    it 'is false when any attribute is present' do
      expect(described_class.new(title: 'A title').empty?).to be(false)
      expect(described_class.new(source_id: 'sul:1234').empty?).to be(false)
      expect(described_class.new(barcode: '36105212345678').empty?).to be(false)
      expect(described_class.new(catalog_record_id: 'in11403803').empty?).to be(false)
    end
  end

  describe 'validation of title' do
    subject(:form) { described_class.new(source_id: 'sul:1234', title:, catalog_record_id:) }

    let(:title) { nil }
    let(:catalog_record_id) { nil }

    before do
      allow(CatalogRepository).to receive(:exists?).and_return(true)
    end

    context 'when neither title nor catalog_record_id is present' do
      it 'is not valid' do
        expect(form).not_to be_valid
        expect(form.errors[:title]).to include('title is required if a FOLIO Instance HRID is not provided')
      end
    end

    context 'when title is present but catalog_record_id is not' do
      let(:title) { 'A title' }

      it 'is valid' do
        expect(form).to be_valid
      end
    end

    context 'when catalog_record_id is present but title is not' do
      let(:catalog_record_id) { 'in11403803' }

      it 'is valid' do
        expect(form).to be_valid
      end
    end
  end

  describe 'validation of catalog record id existence' do
    subject(:form) { described_class.new(source_id: 'sul:1234', catalog_record_id:) }

    let(:catalog_record_id) { 'in11403803' }

    before do
      allow(CatalogRepository).to receive(:exists?).and_return(exists)
    end

    context 'when the catalog record exists' do
      let(:exists) { true }

      it 'is valid' do
        expect(form).to be_valid
        expect(CatalogRepository).to have_received(:exists?)
          .with(catalog_record_id: 'in11403803', allow_catalog_errors: true)
      end
    end

    context 'when the catalog record does not exist' do
      let(:exists) { false }

      it 'is not valid' do
        expect(form).not_to be_valid
        expect(form.errors[:catalog_record_id]).to include('was not found in FOLIO')
      end
    end

    context 'when catalog_record_id is blank' do
      let(:catalog_record_id) { nil }
      let(:exists) { false }

      it 'does not check the catalog' do
        described_class.new(source_id: 'sul:1234', title: 'A title').valid?
        expect(CatalogRepository).not_to have_received(:exists?)
      end
    end

    context 'when catalog_record_id is malformed' do
      let(:catalog_record_id) { 'bogus' }
      let(:exists) { false }

      it 'does not check the catalog' do
        expect(form).not_to be_valid
        expect(CatalogRepository).not_to have_received(:exists?)
      end
    end
  end
end
