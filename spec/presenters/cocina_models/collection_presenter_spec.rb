# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CocinaModels::CollectionPresenter do
  subject(:presenter) { described_class.new(cocina_model) }

  let(:cocina_model) { CocinaModels::Factory.build(cocina_object) }
  let(:cocina_object) { build(:collection_with_metadata) }

  describe '#title' do
    it 'returns the display title' do
      expect(presenter.title).to eq('factory collection title')
    end
  end
end
