# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Search::SortOptions do
  describe '#find_config_by_sort_field' do
    it 'returns the correct sort config for a given sort field' do
      expect(described_class.find_config_by_sort_field('relevance')).to eq(Search::SortOptions::RELEVANCE)
      expect(described_class.find_config_by_sort_field('druid')).to eq(Search::SortOptions::DRUID)
    end

    it 'returns nil for an unknown sort field' do
      expect(described_class.find_config_by_sort_field('unknown_field')).to be_nil
    end
  end
end
