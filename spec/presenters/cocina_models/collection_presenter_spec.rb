# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CocinaModels::CollectionPresenter do
  subject(:presenter) { described_class.new(cocina_model) }

  let(:cocina_model) { instance_double(CocinaModels::Collection, access_view:) }

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
end
