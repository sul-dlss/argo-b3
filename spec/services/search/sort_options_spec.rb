# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Search::SortOptions do
  describe '#find_config_by_sort_field' do
    it 'returns the correct sort config for a given sort field' do
      expect(described_class.find_config_by_sort_field('relevance')).to eq(Search::SortOptions::RELEVANCE)
      expect(described_class.find_config_by_sort_field('last_deposited_date_asc'))
        .to eq(Search::SortOptions::LAST_DEPOSITED_DATE_ASC)
      expect(described_class.find_config_by_sort_field('last_deposited_date_desc'))
        .to eq(Search::SortOptions::LAST_DEPOSITED_DATE_DESC)
      expect(described_class.find_config_by_sort_field('registered_date_asc'))
        .to eq(Search::SortOptions::REGISTERED_DATE_ASC)
      expect(described_class.find_config_by_sort_field('registered_date_desc'))
        .to eq(Search::SortOptions::REGISTERED_DATE_DESC)
      expect(described_class.find_config_by_sort_field('source_id')).to eq(Search::SortOptions::SOURCE_ID)
      expect(described_class.find_config_by_sort_field('title')).to eq(Search::SortOptions::TITLE)
      expect(described_class.find_config_by_sort_field('druid')).to eq(Search::SortOptions::DRUID)
    end

    it 'returns nil for an unknown sort field' do
      expect(described_class.find_config_by_sort_field('unknown_field')).to be_nil
    end
  end
end
