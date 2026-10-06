# frozen_string_literal: true

require 'rails_helper'

RSpec.describe EventsFilterForm do
  describe '.with_defaults' do
    it 'selects the default event types that are available' do
      form = described_class.with_defaults(available_event_types: %w[registration version_open not_a_default])
      expect(form.event_types).to eq(%w[registration version_open])
    end
  end

  describe '#event_types_selected?' do
    it 'is true when event types are selected' do
      expect(described_class.new(event_types: ['', 'registration'])).to be_event_types_selected
    end

    it 'is false when only the blank value from the hidden field is submitted' do
      expect(described_class.new(event_types: [''])).not_to be_event_types_selected
    end
  end

  describe '#event_types_filter' do
    let(:available_event_types) { %w[registration version_open] }

    it 'returns the selected event types when some event types are selected' do
      form = described_class.new(event_types: ['', 'registration'])
      expect(form.event_types_filter(available_event_types:)).to eq(['registration'])
    end

    it 'returns nil when all event types are selected' do
      form = described_class.new(event_types: ['', 'version_open', 'registration'])
      expect(form.event_types_filter(available_event_types:)).to be_nil
    end
  end

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
