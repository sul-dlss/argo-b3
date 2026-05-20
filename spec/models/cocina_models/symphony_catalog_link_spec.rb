# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CocinaModels::SymphonyCatalogLink do
  subject(:symphony_catalog_link) { described_class.new(catalog_record_id: '11403803', refresh: false) }

  describe 'validations' do
    context 'with a valid numeric catalog_record_id' do
      it 'is valid' do
        expect(symphony_catalog_link).to be_valid
      end
    end

    context 'with a blank catalog_record_id' do
      subject(:symphony_catalog_link) { described_class.new(catalog_record_id: '') }

      it 'is not valid' do
        expect(symphony_catalog_link).not_to be_valid
        expect(symphony_catalog_link.errors[:catalog_record_id]).to be_present
      end
    end

    context 'with a non-numeric catalog_record_id' do
      subject(:symphony_catalog_link) { described_class.new(catalog_record_id: 'a11403803') }

      it 'is not valid' do
        expect(symphony_catalog_link).not_to be_valid
        expect(symphony_catalog_link.errors[:catalog_record_id]).to be_present
      end
    end
  end
end
