# frozen_string_literal: true

require 'rails_helper'

RSpec.describe BulkActions::ImportReadUnrestrictedWorkgroupsForm do
  subject(:form) { described_class.new(params) }

  describe 'validations' do
    context 'when a valid csv_file is provided' do
      let(:params) do
        {
          csv_file: fixture_file_upload('import_read_unrestricted_workgroups.csv', 'text/csv')
        }
      end

      it 'is valid' do
        expect(form.valid?).to be true
      end
    end

    context 'when a csv_file missing required headers is provided' do
      let(:params) do
        {
          csv_file: fixture_file_upload('invalid_import_read_unrestricted_workgroups.csv', 'text/csv')
        }
      end

      it 'is invalid' do
        expect(form.valid?).to be false
        expect(form.errors[:csv_file]).to include('missing headers: read_unrestricted.')
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
