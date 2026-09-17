# frozen_string_literal: true

require 'rails_helper'

RSpec.describe FormSerializer do
  let(:form) { ResultsSearchForm.new(query: 'test', object_types: %w[collection item]) }

  it 'serializes and deserializes an ApplicationForm' do
    serialized = described_class.serialize(form)
    # Change to JSON and back to simulate ActiveJob serialization.
    serialized = JSON.parse(serialized.to_json)
    deserialized = described_class.deserialize(serialized)
    expect(deserialized).to be_a(ResultsSearchForm)
    expect(deserialized.attributes).to eq(form.attributes)
  end

  context 'when not an ApplicationForm' do
    let(:form) { Object.new }

    it 'does not serialize the object' do
      expect(described_class.serialize?(form)).to be(false)
    end
  end

  describe '.for' do
    it 'returns the form-specific serializer when there is one' do
      expect(described_class.for(ItemsRegistrationForm.new)).to eq(ItemsRegistrationFormSerializer)
    end

    it 'returns FormSerializer otherwise' do
      expect(described_class.for(form)).to eq(described_class)
    end
  end
end
