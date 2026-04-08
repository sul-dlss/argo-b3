# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CocinaModels::BasePresenter do
  subject(:presenter) { described_class.new(cocina_model) }

  let(:cocina_model) { CocinaModels::Factory.build(cocina_object) }
  let(:cocina_object) { build(:dro_with_metadata) }

  describe '#save!' do
    it 'raises an error' do
      expect { presenter.save! }.to raise_error(RuntimeError, 'save! is not allowed on a presenter.')
    end
  end

  describe '#to_h' do
    context 'when the wrapped cocina object has blank values' do
      let(:cocina_model) { instance_double(CocinaModels::Base, previous_cocina_object: cocina_object) }
      let(:cocina_object) do
        instance_double(Cocina::Models::DROWithMetadata,
                        to_h: {
                          administrative: { hasAdminPolicy: 'druid:hv992ry2431', note: nil },
                          description: { title: [{ value: 'Test title' }], note: '' },
                          identification: { sourceId: '', barcode: nil },
                          structural: { isMemberOf: [] }
                        })
      end

      it 'deeply removes blank values' do
        expect(presenter.to_h).to eq(
          administrative: { hasAdminPolicy: 'druid:hv992ry2431' },
          description: { title: [{ value: 'Test title' }] }
        )
      end
    end
  end

  describe '#cocina_object' do
    it 'returns the previous cocina object' do
      expect(presenter.cocina_object).to eq(cocina_object)
    end
  end

  describe '#admin_policy_druid' do
    it 'returns the druid of the admin policy' do
      expect(presenter.admin_policy_druid).to eq('druid:hv992ry2431')
    end
  end

  describe '#contributors' do
    let(:cocina_object) do
      build(:dro_with_metadata).new(
        description: {
          title: [{ value: 'factory DRO title' }],
          contributor: [
            { name: [{ value: 'Person One' }] },
            { name: [{ value: 'Person Two' }] }
          ],
          purl: 'https://purl.stanford.edu/bc234fg5678'
        }
      )
    end

    it 'joins contributor display names' do
      expect(presenter.contributors).to eq('Person One; Person Two')
    end
  end

  describe '#title' do
    it 'returns the display title' do
      expect(presenter.title).to eq('factory DRO title')
    end
  end
end
