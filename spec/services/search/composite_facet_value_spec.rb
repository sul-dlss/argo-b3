# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Search::CompositeFacetValue do
  describe '.parse' do
    it 'splits the label and druid' do
      expect(described_class.parse('Stanford Theses:druid:bc123df4567'))
        .to eq ['druid:bc123df4567', 'Stanford Theses']
    end

    it 'anchors on the trailing druid when the label contains a colon' do
      expect(described_class.parse('Title: A Subtitle:druid:bc123df4567'))
        .to eq ['druid:bc123df4567', 'Title: A Subtitle']
    end

    it 'anchors on the trailing druid when the label contains a literal ":druid:"' do
      expect(described_class.parse('My :druid: Collection:druid:bc123df4567'))
        .to eq ['druid:bc123df4567', 'My :druid: Collection']
    end

    it 'falls back to the raw value when it does not match the expected format' do
      expect(described_class.parse('not a composite value')).to eq ['not a composite value', 'not a composite value']
    end
  end
end
