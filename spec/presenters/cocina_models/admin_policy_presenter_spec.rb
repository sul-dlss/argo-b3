# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CocinaModels::AdminPolicyPresenter do
  subject(:presenter) { described_class.new(cocina_model) }

  let(:druid) { 'druid:bc123df4567' }
  let(:cocina_model) { instance_double(CocinaModels::AdminPolicy, druid:) }

  before do
    allow(Searchers::QueryCount).to receive(:call).and_return(12)
  end

  describe '#item_count' do
    it 'returns the number of items governed by the admin policy' do
      expect(presenter.item_count).to eq(12)

      expect(Searchers::QueryCount).to have_received(:call).with(
        query: "#{Search::Fields::APO_DRUID}:\"#{druid}\" AND #{Search::Fields::OBJECT_TYPES}:\"item\""
      )
    end
  end

  describe '#collection_count' do
    it 'returns the number of collections governed by the admin policy' do
      expect(presenter.collection_count).to eq(12)

      expect(Searchers::QueryCount).to have_received(:call).with(
        query: "#{Search::Fields::APO_DRUID}:\"#{druid}\" AND #{Search::Fields::OBJECT_TYPES}:\"collection\""
      )
    end
  end
end
