# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CocinaModels::FolioCatalogLink do
  subject(:folio_catalog_link) { described_class.new(catalog_record_id: 'in11403803', refresh: false) }

  describe 'validations' do
    context 'with a migrated-from-Symphony catalog_record_id (a prefix)' do
      subject(:folio_catalog_link) { described_class.new(catalog_record_id: 'a11403803', refresh: false) }

      it 'is valid' do
        expect(folio_catalog_link).to be_valid
      end
    end

    context 'with a migrated-from-Voyager catalog_record_id (L prefix)' do
      subject(:folio_catalog_link) { described_class.new(catalog_record_id: 'L11403803', refresh: false) }

      it 'is valid' do
        expect(folio_catalog_link).to be_valid
      end
    end

    context 'with a created-in-Folio catalog_record_id (in prefix)' do
      it 'is valid' do
        expect(folio_catalog_link).to be_valid
      end
    end

    context 'with a blank catalog_record_id' do
      subject(:folio_catalog_link) { described_class.new(catalog_record_id: '') }

      it 'is not valid' do
        expect(folio_catalog_link).not_to be_valid
        expect(folio_catalog_link.errors[:catalog_record_id]).to be_present
      end
    end

    context 'with a symphony-format catalog_record_id' do
      subject(:folio_catalog_link) { described_class.new(catalog_record_id: '11403803', refresh: false) }

      it 'is not valid' do
        expect(folio_catalog_link).not_to be_valid
        expect(folio_catalog_link.errors[:catalog_record_id]).to be_present
      end
    end

    context 'when sort_key is present without part_label' do
      subject(:folio_catalog_link) do
        described_class.new(catalog_record_id: 'in11403803', refresh: false, sort_key: 'vol. 1')
      end

      it 'is not valid' do
        expect(folio_catalog_link).not_to be_valid
        expect(folio_catalog_link.errors[:sort_key]).to be_present
      end
    end

    context 'when sort_key and part_label are both present' do
      subject(:folio_catalog_link) do
        described_class.new(catalog_record_id: 'in11403803', refresh: false, part_label: 'vol. 1', sort_key: 'vol. 1')
      end

      it 'is valid' do
        expect(folio_catalog_link).to be_valid
      end
    end
  end
end
