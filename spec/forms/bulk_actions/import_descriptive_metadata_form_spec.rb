# frozen_string_literal: true

require 'rails_helper'

RSpec.describe BulkActions::ImportDescriptiveMetadataForm do
  subject(:form) { described_class.new(params) }

  describe 'validations' do
    context 'when an invalid csv_file is provided' do
      let(:params) do
        {
          csv_file: fixture_file_upload('invalid_bulk_upload_descriptive.csv', 'text/csv')
        }
      end

      it 'is invalid' do
        expect(form.valid?).to be false
        expect(form.errors[:csv_file])
          .to eq(['Missing title structured value for title2.structuredValue2.type. ' \
                  'Expected title2.structuredValue2.value.', 'Column header invalid: xsource_id'])
      end
    end
  end
end
