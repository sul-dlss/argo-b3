# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Searchers::AdminPolicyObjectCounts do
  subject(:object_counts) { described_class.call(admin_policy_druid:) }

  let(:admin_policy_druid) { 'druid:bc123df4567' }

  before do
    allow(Searchers::QueryCount).to receive(:call).and_return(12, 3)
  end

  it 'returns the item and collection counts for the admin policy' do
    expect(object_counts.item_count).to eq(12)
    expect(object_counts.collection_count).to eq(3)

    expect(Searchers::QueryCount).to have_received(:call).with(
      query: "#{Search::Fields::APO_DRUID}:\"#{admin_policy_druid}\" AND #{Search::Fields::OBJECT_TYPES}:\"item\""
    )
    expect(Searchers::QueryCount).to have_received(:call).with(
      query: "#{Search::Fields::APO_DRUID}:\"#{admin_policy_druid}\" AND #{Search::Fields::OBJECT_TYPES}:\"collection\""
    )
  end
end
