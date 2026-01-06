# frozen_string_literal: true

require 'rails_helper'

RSpec.describe BulkActions::RegisterForm do
  subject(:form) { described_class.new(csv_file:) }

  describe 'validations' do
    context 'when a valid csv_file is provided' do
      let(:csv_file) { fixture_file_upload('bulk_register.csv', 'text/csv') }

      it 'is valid' do
        expect(form.valid?).to be true
      end
    end

    context 'when an incomplete csv_file is provided' do
      let(:csv_file) { fixture_file_upload('bulk_register_bad.csv', 'text/csv') }

      it 'is invalid' do
        expect(form.valid?).to be false
        expect(form.errors[:csv_file])
          .to eq(['missing headers: administrative_policy_object.'])
      end
    end
  end
end
