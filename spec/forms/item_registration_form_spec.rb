# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ItemRegistrationForm do
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
end
