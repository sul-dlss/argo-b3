# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Searchers::AdminPolicyObjectCounts do
  subject(:object_counts) { described_class.call(admin_policy_druid:, user_scope:) }

  let(:admin_policy_druid) { 'druid:bc123df4567' }
  let(:user_scope) { Permissions::UserScope.new(groups: []) }

  before do
    allow(Searchers::QueryCount).to receive(:call).and_return(12, 3)
  end

  it 'returns the item and collection counts for the admin policy' do
    expect(object_counts.item_count).to eq(12)
    expect(object_counts.collection_count).to eq(3)

    expect(Searchers::QueryCount).to have_received(:call).with(
      query: "#{Search::Fields::APO_DRUID}:\"#{admin_policy_druid}\" AND #{Search::Fields::OBJECT_TYPES}:\"item\"",
      user_scope:
    )
    expect(Searchers::QueryCount).to have_received(:call).with(
      query: "#{Search::Fields::APO_DRUID}:\"#{admin_policy_druid}\" AND #{Search::Fields::OBJECT_TYPES}:\"collection\"",
      user_scope:
    )
  end
end
