# frozen_string_literal: true

require 'rails_helper'

RSpec.describe EventsFilterForm do
  describe '#from_time' do
    it 'parses the datetime-local value as Pacific time' do
      expect(described_class.new(from: '2026-01-15T10:30').from_time).to eq(Time.utc(2026, 1, 15, 18, 30))
    end

    it 'returns nil when blank' do
      expect(described_class.new(from: '').from_time).to be_nil
    end

    it 'returns nil when invalid' do
      expect(described_class.new(from: 'not-a-date').from_time).to be_nil
    end
  end

  describe '#to_time' do
    it 'parses the datetime-local value as Pacific time' do
      expect(described_class.new(to: '2026-07-04T08:00').to_time).to eq(Time.utc(2026, 7, 4, 15, 0))
    end

    it 'returns nil when blank' do
      expect(described_class.new(to: nil).to_time).to be_nil
    end
  end
end
