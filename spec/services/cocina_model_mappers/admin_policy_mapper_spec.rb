# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CocinaModelMappers::AdminPolicyMapper do
  describe '.call' do
    subject(:result) { described_class.call(cocina_object:) }

    let(:license) { 'https://creativecommons.org/publicdomain/zero/1.0/legalcode' }
    let(:use_and_reproduction_statement) { 'This is a use and reproduction statement.' }
    let(:copyright) { 'Copyright © Stanford University. All Rights Reserved.' }
    let(:view) { 'stanford' }
    let(:download) { 'location-based' }
    let(:location) { Constants::ACCESS_LOCATIONS.first }
    let(:admin_policy_druid) { 'druid:hv992ry2431' }
    let(:agreement_druid) { 'druid:bb008zm4587' }

    let(:cocina_object) do
      build(:admin_policy_with_metadata).new(
        administrative: {
          hasAdminPolicy: admin_policy_druid,
          hasAgreement: agreement_druid,
          accessTemplate: {
            view:,
            download:,
            location:,
            useAndReproductionStatement: use_and_reproduction_statement,
            license:,
            copyright:
          }
        }
      )
    end

    it 'returns a hash from the cocina object' do
      expect(result).to eq(
        access_view: view,
        access_download: download,
        access_location: location,
        use_and_reproduction_statement:,
        license:,
        copyright:,
        admin_policy_druid:,
        agreement_druid:
      )
    end

    context 'when the cocina object has no location, use statement, license, or copyright' do
      let(:view) { 'world' }
      let(:download) { 'world' }
      let(:cocina_object) do
        build(:admin_policy_with_metadata).new(
          administrative: {
            hasAdminPolicy: admin_policy_druid,
            hasAgreement: agreement_druid,
            accessTemplate: {
              view:,
              download:
            }
          }
        )
      end

      it 'omits the blank attributes' do
        expect(result).to eq(
          access_view: view,
          access_download: download,
          admin_policy_druid:,
          agreement_druid:
        )
      end
    end
  end
end
