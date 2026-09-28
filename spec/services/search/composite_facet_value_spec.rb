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

    it 'splits the label and URI' do
      expect(described_class.parse('CC Zero 1.0:https://creativecommons.org/publicdomain/zero/1.0/legalcode'))
        .to eq ['https://creativecommons.org/publicdomain/zero/1.0/legalcode', 'CC Zero 1.0']
    end

    it 'splits the label and URI when the label is the URI' do
      expect(described_class.parse('http://opendatacommons.org/licenses/odbl/1.0/:http://opendatacommons.org/licenses/odbl/1.0/'))
        .to eq ['http://opendatacommons.org/licenses/odbl/1.0/', 'http://opendatacommons.org/licenses/odbl/1.0/']
    end

    it 'splits the label and URI when the URI contains a port' do
      expect(described_class.parse('My License:https://example.com:8080/license'))
        .to eq ['https://example.com:8080/license', 'My License']
    end

    it 'splits the label and URI when the label contains a colon' do
      expect(described_class.parse('License: Version 2:https://example.com/license'))
        .to eq ['https://example.com/license', 'License: Version 2']
    end

    it 'falls back to the raw value when it does not match the expected format' do
      expect(described_class.parse('not a composite value')).to eq ['not a composite value', 'not a composite value']
    end
  end
end
