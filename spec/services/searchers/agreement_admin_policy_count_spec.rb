# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Searchers::AgreementAdminPolicyCount do
  subject(:admin_policy_count) { described_class.call(agreement_druid:, user_scope:) }

  let(:agreement_druid) { 'druid:bc123df4567' }
  let(:user_scope) { Permissions::UserScope.new(groups: []) }

  before do
    allow(Searchers::QueryCount).to receive(:call).and_return(7)
  end

  it 'returns the number of APOs with the agreement' do
    expect(admin_policy_count).to eq(7)

    expect(Searchers::QueryCount).to have_received(:call).with(
      query: 'agreement_ssi:"druid:bc123df4567"', user_scope:
    )
  end
end
