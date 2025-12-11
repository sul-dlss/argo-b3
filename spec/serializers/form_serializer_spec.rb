# frozen_string_literal: true

require 'rails_helper'

RSpec.describe FormSerializer do
  let(:form) { SearchForm.new(query: 'test', include_google_books: true, object_types: %w[collection item]) }

  it 'serializes and deserializes an ApplicationForm' do
    serialized = described_class.serialize(form)
    # Change to JSON and back to simulate ActiveJob serialization.
    serialized = JSON.parse(serialized.to_json)
    deserialized = described_class.deserialize(serialized)
    expect(deserialized).to be_a(SearchForm)
    expect(deserialized.attributes).to eq(form.attributes)
  end

  context 'when not an ApplicationForm' do
    let(:form) { Object.new }

    it 'does not serialize the object' do
      expect(described_class.serialize?(form)).to be(false)
    end
  end
end
