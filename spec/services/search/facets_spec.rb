# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Search::Facets do
  describe '#find_config_by_form_field' do
    it 'returns the correct facet config for a given form field' do
      expect(described_class.find_config_by_form_field(:object_types)).to eq(Search::Facets::OBJECT_TYPES)
    end

    it 'returns nil for an unknown form field' do
      expect(described_class.find_config_by_form_field(:unknown_field)).to be_nil
    end
  end

  describe '#missing_value?' do
    it 'returns true for the missing value' do
      expect(described_class.missing_value?('_missing_value')).to be true
    end

    it 'returns false for other values' do
      expect(described_class.missing_value?('English')).to be false
    end
  end
end
