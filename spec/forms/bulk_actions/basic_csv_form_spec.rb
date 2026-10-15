# frozen_string_literal: true

require 'rails_helper'

RSpec.describe BulkActions::BasicCsvForm do
  subject(:form) { described_class.new(params) }

  let(:params) { {} }

  describe 'validations' do
    context 'when no csv_file is provided' do
      it 'is invalid' do
        expect(form.valid?).to be false
        expect(form.errors[:csv_file]).to include("can't be blank")
      end
    end

    context 'when a csv_file is provided' do
      let(:params) do
        {
          csv_file: fixture_file_upload('descriptive-upload.csv', 'text/csv')
        }
      end

      it 'is valid' do
        expect(form.valid?).to be true
      end
    end

    context 'when the csv_file cannot be read' do
      let(:params) do
        {
          csv_file: fixture_file_upload('catalog_record_id_and_barcode.xls')
        }
      end

      it 'is invalid' do
        expect(form.valid?).to be false
        expect(form.errors[:csv_file]).to eq(['Unsupported upload file type'])
      end
    end
  end
end
