# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CocinaModels::CollectionPresenter do
  subject(:presenter) { described_class.new(cocina_model) }

  let(:druid) { 'druid:bc123df4567' }
  let(:access_view) { 'world' }
  let(:cocina_model) { instance_double(CocinaModels::Collection, access_view:, druid:) }

  describe '#display_access_rights' do
    context 'when access_view is world' do
      let(:access_view) { 'world' }

      it 'returns a humanized world access label' do
        expect(presenter.display_access_rights).to eq('View: World')
      end
    end

    context 'when access_view is dark' do
      let(:access_view) { 'dark' }

      it 'returns a humanized dark access label' do
        expect(presenter.display_access_rights).to eq('View: Dark')
      end
    end
  end

  describe '#item_count' do
    before do
      allow(Searchers::QueryCount).to receive(:call).and_return(12)
    end

    it 'returns the number of items in the collection' do
      expect(presenter.item_count).to eq(12)

      expect(Searchers::QueryCount).to have_received(:call).with(
        query: "#{Search::Fields::COLLECTION_DRUIDS}:\"#{druid}\""
      )
    end
  end
end
