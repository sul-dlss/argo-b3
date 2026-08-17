# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CocinaModels::AdminPolicy do
  subject(:admin_policy) { described_class.build_from_cocina_object(cocina_object) }

  let(:cocina_object) { build(:admin_policy_with_metadata) }

  describe '.build_from_cocina_object' do
    context 'with a valid Cocina::Models::AdminPolicyWithMetadata' do
      it 'initializes with a Cocina::Models::AdminPolicyWithMetadata' do
        expect(admin_policy.external_identifier).to eq(cocina_object.externalIdentifier)
        expect(admin_policy.agreement_druid).to eq(cocina_object.administrative.hasAgreement)
      end
    end

    context 'with an invalid object' do
      let(:cocina_object) { 'invalid' }

      it 'raises an error if initialized with an invalid object' do
        expect { admin_policy }.to raise_error(ArgumentError)
      end
    end
  end

  describe 'type predicates' do
    it 'returns false for #dro?' do
      expect(admin_policy.dro?).to be false
    end

    it 'returns false for #collection?' do
      expect(admin_policy.collection?).to be false
    end

    it 'returns true for #admin_policy?' do
      expect(admin_policy.admin_policy?).to be true
    end
  end

  describe 'agreement_druid' do
    context 'when blank' do
      before { admin_policy.agreement_druid = nil }

      it 'is not valid' do
        expect(admin_policy).not_to be_valid
        expect(admin_policy.errors[:agreement_druid]).to include("can't be blank")
      end
    end
  end

  describe '#create!' do
    let(:user_name) { 'test_user' }

    context 'when the object has already been persisted' do
      it 'raises' do
        expect { admin_policy.create!(user_name:) }.to raise_error(/already been persisted/)
      end
    end

    context 'when the object has not been persisted' do
      let(:new_admin_policy) do
        described_class.new(agreement_druid: 'druid:bb008zm4587',
                            access_view: 'world', access_download: 'world',
                            admin_policy_druid: 'druid:hv992ry2431')
      end
      let(:request_cocina_object) { instance_double(Cocina::Models::RequestAdminPolicy) }
      let(:registered_cocina_object) { build(:admin_policy_with_metadata) }

      before do
        allow(new_admin_policy).to receive(:request_cocina_object).and_return(request_cocina_object)
        allow(Sdr::Repository).to receive(:register).and_return(registered_cocina_object)
      end

      it 'registers the object and repopulates the model' do
        new_admin_policy.create!(user_name:)

        expect(Sdr::Repository).to have_received(:register)
          .with(request_cocina_object:, user_name:)
        expect(new_admin_policy.persisted?).to be true
        expect(new_admin_policy.external_identifier).to eq(registered_cocina_object.externalIdentifier)
        expect(new_admin_policy.changed?).to be false
      end
    end

    context 'when building the real request cocina object' do
      let(:new_admin_policy) do
        described_class.new(agreement_druid: 'druid:bb008zm4587',
                            access_view: 'world', access_download: 'world',
                            admin_policy_druid: 'druid:hv992ry2431')
      end
      let(:registered_cocina_object) { build(:admin_policy_with_metadata) }

      before do
        allow(Sdr::Repository).to receive(:register).and_return(registered_cocina_object)
      end

      it 'constructs and registers a valid Cocina::Models::RequestAdminPolicy' do
        new_admin_policy.create!(user_name:)

        expect(Sdr::Repository).to have_received(:register) do |args|
          request_cocina_object = args[:request_cocina_object]
          expect(request_cocina_object).to be_a(Cocina::Models::RequestAdminPolicy)
          expect(request_cocina_object.administrative.hasAdminPolicy).to eq('druid:hv992ry2431')
          expect(request_cocina_object.administrative.hasAgreement).to eq('druid:bb008zm4587')
          expect(request_cocina_object.administrative.accessTemplate.view).to eq('world')
          expect(request_cocina_object.administrative.accessTemplate.download).to eq('world')

          expect(args[:user_name]).to eq(user_name)
        end
      end
    end
  end
end
