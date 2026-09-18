# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Searchers::CollectionItemCount do
  subject(:item_count) { described_class.call(collection_druid:) }

  let(:collection_druid) { 'druid:bc123df4567' }

  before do
    allow(Searchers::QueryCount).to receive(:call).and_return(12)
  end

  it 'returns the number of items in the collection' do
    expect(item_count).to eq(12)

    expect(Searchers::QueryCount).to have_received(:call).with(
      query: "#{Search::Fields::COLLECTION_DRUIDS}:\"#{collection_druid}\""
    )
  end
end
