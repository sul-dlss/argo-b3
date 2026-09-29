# frozen_string_literal: true

require 'rails_helper'

RSpec.describe UriSupport do
  describe '.last' do
    it 'returns the last segment of the URI' do
      expect(described_class.last(uri: Cocina::Models::ObjectType.book)).to eq('book')
    end

    it 'returns the last segment of a URI with a hyphenated segment' do
      expect(described_class.last(uri: Cocina::Models::ObjectType.webarchive_seed)).to eq('webarchive-seed')
    end
  end
end
