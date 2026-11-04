# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CocinaObjectMutators::AdminPolicyMutator do
  subject(:result) { described_class.call(cocina_object:, cocina_model:) }

  let(:cocina_object) do
    build(:admin_policy_with_metadata, id: 'druid:bc123df4567', title: 'My APO').new(
      administrative: {
        hasAdminPolicy: 'druid:hv992ry2431',
        hasAgreement: 'druid:hp308wm0436',
        registrationWorkflow: ['goobiWF'],
        accessTemplate: {
          view: 'location-based',
          download: 'location-based',
          location: 'spec',
          useAndReproductionStatement: 'Use at will.',
          copyright: 'Copyright © Stanford.',
          license: 'https://creativecommons.org/licenses/by/4.0/legalcode'
        }
      }
    )
  end
  let(:cocina_model) { CocinaModels::AdminPolicy.build_from_cocina_object(cocina_object) }

  context 'when the cocina model is unchanged' do
    it 'returns an equivalent AdminPolicyWithMetadata with the lock' do
      expect(result).to be_a(Cocina::Models::AdminPolicyWithMetadata)
      expect(result).to eq(cocina_object)
      expect(result.lock).to eq(cocina_object.lock)
    end
  end

  context 'when the cocina model has an updated title, agreement, and object defaults' do
    before do
      cocina_model.description_hash = { title: [{ value: 'My new APO' }] }
      cocina_model.agreement_druid = 'druid:bb008zm4587'
      cocina_model.access_view = 'world'
      cocina_model.access_download = 'world'
      cocina_model.access_location = nil
      cocina_model.use_and_reproduction_statement = 'Property rights reside with the repository.'
      cocina_model.copyright = ''
      cocina_model.license = ''
    end

    it 'returns an AdminPolicyWithMetadata with the updates, retaining the purl and other administrative metadata' do
      expect(result.description.title.first.value).to eq('My new APO')
      expect(result.description.purl).to eq('https://purl.stanford.edu/bc123df4567')
      expect(result.administrative.hasAgreement).to eq('druid:bb008zm4587')
      expect(result.administrative.hasAdminPolicy).to eq('druid:hv992ry2431')
      expect(result.administrative.registrationWorkflow).to eq(['goobiWF'])
      expect(result.administrative.accessTemplate.to_h).to eq(
        view: 'world',
        download: 'world',
        controlledDigitalLending: false,
        useAndReproductionStatement: 'Property rights reside with the repository.'
      )
    end
  end
end
