# frozen_string_literal: true

require 'rails_helper'

RSpec.describe BulkActions::ImportStructuralMetadataForm do
  subject(:form) { described_class.new(params) }

  describe 'validations' do
    context 'when a valid csv_file is provided' do
      let(:params) { { csv_file: fixture_file_upload('bulk_upload_structural.csv', 'text/csv') } }

      it 'is valid' do
        expect(form.valid?).to be true
      end
    end

    context 'when a csv_file missing the druid header is provided' do
      let(:params) { { csv_file: fixture_file_upload('invalid_bulk_upload_structural.csv', 'text/csv') } }

      it 'is invalid' do
        expect(form.valid?).to be false
        expect(form.errors[:csv_file]).to include('missing headers: druid.')
      end
    end

    context 'when no csv_file is provided' do
      let(:params) { {} }

      it 'is invalid' do
        expect(form.valid?).to be false
        expect(form.errors[:csv_file]).to include("can't be blank")
      end
    end
  end
end
