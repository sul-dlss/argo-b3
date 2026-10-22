# frozen_string_literal: true

require 'rails_helper'

RSpec.describe AdditionalCatalogRecordIdForm do
  subject(:form) { described_class.new(catalog_record_id:) }

  let(:catalog_record_id) { 'in11403803' }
  let(:exists) { true }

  before { allow(CatalogRepository).to receive(:exists?).and_return(exists) }

  context 'when blank' do
    let(:catalog_record_id) { '' }

    it 'is valid without checking FOLIO' do
      expect(form).to be_valid
      expect(CatalogRepository).not_to have_received(:exists?)
    end
  end

  context 'when the format is invalid' do
    let(:catalog_record_id) { 'x123' }

    it 'is invalid without checking FOLIO' do
      expect(form).not_to be_valid
      expect(form.errors[:catalog_record_id]).to be_present
      expect(CatalogRepository).not_to have_received(:exists?)
    end
  end

  context 'when found in FOLIO' do
    it 'is valid, checking FOLIO once across validations' do
      expect(form).to be_valid
      expect(form).to be_valid
      expect(CatalogRepository).to have_received(:exists?)
        .with(catalog_record_id: 'in11403803', allow_catalog_errors: true).once
    end
  end

  context 'when not found in FOLIO' do
    let(:exists) { false }

    it 'is invalid' do
      expect(form).not_to be_valid
      expect(form.errors[:catalog_record_id]).to eq(['was not found in FOLIO'])
    end
  end

  context 'when already linked to the object' do
    before { form.linked_catalog_record_ids = ['in11403803'] }

    it 'is valid without checking FOLIO' do
      expect(form).to be_valid
      expect(CatalogRepository).not_to have_received(:exists?)
    end
  end
end
