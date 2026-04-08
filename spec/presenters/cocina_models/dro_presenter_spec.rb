# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CocinaModels::DroPresenter do
  subject(:presenter) { described_class.new(cocina_model) }

  let(:cocina_model) { CocinaModels::Factory.build(cocina_object) }

  let(:cocina_object) do
    build(:dro_with_metadata).new(
      structural: { isMemberOf: collection_druids }
    )
  end

  let(:collection_druids) { ['druid:bb123cd4567', 'druid:cc123cd4578'] }

  describe '#collection_druids' do
    it 'returns the druids of the collections' do
      expect(presenter.collection_druids).to eq(collection_druids)
    end
  end

  describe '#title' do
    it 'returns the display title' do
      expect(presenter.title).to eq('factory DRO title')
    end
  end
end
