# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Reports::Fields do
  describe '#find_config_by_field' do
    it 'returns the correct config for a given field' do
      expect(described_class.find_config_by_field(Search::Fields::OBJECT_TYPES)).to eq(Reports::Fields::OBJECT_TYPE)
    end

    it 'returns nil for an unknown field' do
      expect(described_class.find_config_by_field('unknown_field')).to be_nil
    end
  end
end
