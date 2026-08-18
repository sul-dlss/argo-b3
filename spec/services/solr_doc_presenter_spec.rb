# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SolrDocPresenter do
  subject(:presenter) { described_class.new(solr_doc:) }

  let(:solr_doc) do
    {
      Search::Fields::ID => 'druid:bc123df4567',
      Search::Fields::OBJECT_TYPES => [object_type]
    }
  end

  describe '#collection?' do
    context 'when the object type is collection' do
      let(:object_type) { 'collection' }

      it 'returns true' do
        expect(presenter.collection?).to be true
      end
    end

    context 'when the object type is not collection' do
      let(:object_type) { 'item' }

      it 'returns false' do
        expect(presenter.collection?).to be false
      end
    end
  end

  describe '#admin_policy?' do
    context 'when the object type is admin policy' do
      let(:object_type) { 'adminPolicy' }

      it 'returns true' do
        expect(presenter.admin_policy?).to be true
      end
    end

    context 'when the object type is not admin policy' do
      let(:object_type) { 'item' }

      it 'returns false' do
        expect(presenter.admin_policy?).to be false
      end
    end
  end

  describe '#agreement?' do
    context 'when the object type is agreement' do
      let(:object_type) { 'agreement' }

      it 'returns true' do
        expect(presenter.agreement?).to be true
      end
    end

    context 'when the object type is not agreement' do
      let(:object_type) { 'item' }

      it 'returns false' do
        expect(presenter.agreement?).to be false
      end
    end
  end

  describe '#virtual_object?' do
    context 'when the object type is virtual object' do
      let(:object_type) { 'virtual object' }

      it 'returns true' do
        expect(presenter.virtual_object?).to be true
      end
    end

    context 'when the object type is not agreement' do
      let(:object_type) { 'item' }

      it 'returns false' do
        expect(presenter.agreement?).to be false
      end
    end
  end

  describe '#dro?' do
    context 'when the object type is collection' do
      let(:object_type) { 'collection' }

      it 'returns false' do
        expect(presenter.dro?).to be false
      end
    end

    context 'when the object type is agreement' do
      let(:object_type) { 'agreement' }

      it 'returns false' do
        expect(presenter.dro?).to be false
      end
    end

    context 'when the object type is admin policy' do
      let(:object_type) { 'adminPolicy' }

      it 'returns false' do
        expect(presenter.dro?).to be false
      end
    end

    context 'when the object type is neither collection nor admin policy' do
      let(:object_type) { 'item' }

      it 'returns true' do
        expect(presenter.dro?).to be true
      end
    end
  end

  describe '#dro_or_collection?' do
    context 'when the object type is item' do
      let(:object_type) { 'item' }

      it 'returns true' do
        expect(presenter.dro_or_collection?).to be true
      end
    end

    context 'when the object type is collection' do
      let(:object_type) { 'collection' }

      it 'returns true' do
        expect(presenter.dro_or_collection?).to be true
      end
    end

    context 'when the object type is virtual object' do
      let(:object_type) { 'virtual object' }

      it 'returns true' do
        expect(presenter.dro_or_collection?).to be true
      end
    end

    context 'when the object type is admin policy' do
      let(:object_type) { 'adminPolicy' }

      it 'returns false' do
        expect(presenter.dro_or_collection?).to be false
      end
    end

    context 'when the object type is agreement' do
      let(:object_type) { 'agreement' }

      it 'returns false' do
        expect(presenter.dro_or_collection?).to be false
      end
    end
  end
end
