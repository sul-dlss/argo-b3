# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CocinaModels::PresenterFactory do
  describe '.build' do
    context 'with a CocinaModels::Dro' do
      let(:cocina_model) { CocinaModels::Factory.build(build(:dro_with_metadata)) }

      it 'returns a CocinaModels::DroPresenter' do
        result = described_class.build(cocina_model)

        expect(result).to be_a(CocinaModels::DroPresenter)
        expect(result.title).to eq('factory DRO title')
      end
    end

    context 'with a CocinaModels::Collection' do
      let(:cocina_model) { CocinaModels::Factory.build(build(:collection_with_metadata)) }

      it 'returns a CocinaModels::CollectionPresenter' do
        result = described_class.build(cocina_model)

        expect(result).to be_a(CocinaModels::CollectionPresenter)
        expect(result.title).to eq('factory collection title')
      end
    end

    context 'with a CocinaModels::AdminPolicy' do
      let(:cocina_model) { CocinaModels::Factory.build(build(:admin_policy_with_metadata)) }

      it 'returns a CocinaModels::AdminPolicyPresenter' do
        result = described_class.build(cocina_model)

        expect(result).to be_a(CocinaModels::AdminPolicyPresenter)
        expect(result.title).to eq('factory APO title')
      end
    end

    context 'with an invalid object' do
      let(:cocina_model) { 'invalid' }

      it 'raises an ArgumentError' do
        expect { described_class.build(cocina_model) }
          .to raise_error(ArgumentError,
                          'Expected a CocinaModels::Dro, CocinaModels::Collection, or CocinaModels::AdminPolicy')
      end
    end
  end

  describe '.find_and_build' do
    let(:druid) { 'druid:bc234fg5678' }

    context 'when structural is true' do
      let(:cocina_object) { build(:dro_with_metadata, id: druid) }

      before do
        allow(Sdr::Repository).to receive(:find).and_return(cocina_object)
      end

      it 'finds the cocina object and returns a presenter' do
        result = described_class.find_and_build(druid)

        expect(result).to be_a(CocinaModels::DroPresenter)
        expect(result.title).to eq('factory DRO title')
        expect(Sdr::Repository).to have_received(:find).with(druid:)
      end
    end

    context 'when structural is false' do
      let(:cocina_object) { build(:collection_lite) }

      before do
        allow(described_class).to receive(:find_lite).and_return(cocina_object)
      end

      it 'uses the lite finder and returns a presenter' do
        result = described_class.find_and_build(druid, structural: false)

        expect(result).to be_a(CocinaModels::CollectionPresenter)
        expect(result.title).to eq('factory collection title')
        expect(described_class).to have_received(:find_lite).with(druid)
      end
    end

    context 'when the cocina object is a DRO and structural is false' do
      let(:cocina_object) { build(:dro_lite) }

      before do
        allow(described_class).to receive(:find_lite).and_return(cocina_object)
      end

      it 'uses the lite finder and returns a presenter' do
        result = described_class.find_and_build(druid, structural: false)

        expect(result).to be_a(CocinaModels::DroPresenter)
        expect(result.title).to eq('factory DRO title')
        expect(described_class).to have_received(:find_lite).with(druid)
      end
    end
  end

  describe '.find_lite' do
    let(:druid) { 'druid:bc234fg5678' }

    context 'when the cocina object is not a DRO lite object' do
      let(:cocina_object) { build(:collection_lite) }

      before do
        allow(Sdr::Repository).to receive(:find_lite).and_return(cocina_object)
        allow(Searchers::SingleItemByDruid).to receive(:call)
      end

      it 'returns the cocina object unchanged' do
        result = described_class.send(:find_lite, druid)

        expect(result).to eq(cocina_object)
        expect(Sdr::Repository).to have_received(:find_lite).with(druid:, structural: false)
        expect(Searchers::SingleItemByDruid).not_to have_received(:call)
      end
    end

    context 'when the cocina object is a DRO lite object' do
      let(:cocina_object) { build(:dro_lite, id: druid) }
      let(:collection_druids) { ['druid:bb123cd4567', 'druid:cc123cd4578'] }
      let(:search_result) do
        SearchResults::Item.new(
          solr_doc: {
            Search::Fields::ID => druid,
            Search::Fields::COLLECTION_DRUIDS => collection_druids
          },
          index: 1
        )
      end

      before do
        allow(Sdr::Repository).to receive(:find_lite).and_return(cocina_object)
        allow(Searchers::SingleItemByDruid).to receive(:call).and_return(search_result)
      end

      it 'adds collection druids to the structural metadata' do
        result = described_class.send(:find_lite, druid)

        expect(result).to be_a(Cocina::Models::DROLite)
        expect(result.structural.isMemberOf).to eq(collection_druids)
        expect(Sdr::Repository).to have_received(:find_lite).with(druid:, structural: false)
        expect(Searchers::SingleItemByDruid).to have_received(:call)
          .with(druid:, fields: Search::Fields::COLLECTION_DRUIDS)
      end
    end
  end
end
