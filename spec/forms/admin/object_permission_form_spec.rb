# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Admin::ObjectPermissionForm do
  subject(:form) { described_class.new(target_druid:, workgroup:, permission_type:) }

  let(:target_druid) { 'druid:bc123df4567' }
  let(:workgroup) { 'sdr:alpha' }
  let(:permission_type) { 'edit' }

  before do
    allow(Sdr::Event).to receive(:create)
  end

  describe '.permitted_params' do
    it 'does not permit the target druid' do
      expect(described_class.permitted_params).to eq(%i[workgroup permission_type])
    end
  end

  describe 'validation' do
    it 'is valid for a new workgroup and permission' do
      expect(form).to be_valid
    end

    context 'when the workgroup is blank' do
      let(:workgroup) { ' ' }

      it 'is not valid' do
        expect(form).not_to be_valid
        expect(form.errors[:workgroup]).to eq(["can't be blank"])
      end
    end

    context 'when the workgroup already has the permission for the object' do
      before do
        create(:permission, :edit, workgroup:, target_druid:)
      end

      it 'is not valid' do
        expect(form).not_to be_valid
        expect(form.errors[:workgroup]).to eq(['already has this permission'])
      end
    end

    context 'when the workgroup has a different permission for the object' do
      before do
        create(:permission, :read_restricted, workgroup:, target_druid:)
      end

      it 'is valid' do
        expect(form).to be_valid
      end
    end
  end

  describe '#workgroup_options' do
    before do
      create(:permission, :read_unrestricted, workgroup: 'sdr:gamma')
      create(:permission, :edit, workgroup: 'sdr:beta')
      create(:permission, :read_restricted, workgroup: 'sdr:beta')
      create(:permission, :admin, workgroup: 'sdr:alpha')
    end

    it 'returns every workgroup with any permission (including the seeded admin workgroup), once each, sorted' do
      expect(form.workgroup_options).to eq(%w[sdr:alpha sdr:argo_administrators sdr:beta sdr:gamma])
    end

    context 'when the entered workgroup does not have any permissions' do
      let(:workgroup) { 'sdr:delta' }

      it 'includes the entered workgroup' do
        expect(form.workgroup_options).to eq(%w[sdr:alpha sdr:argo_administrators sdr:beta sdr:delta sdr:gamma])
      end
    end
  end

  describe '#save!' do
    let(:workgroup) { '  sdr:alpha ' }

    it 'creates the permission with the whitespace-stripped workgroup' do
      permission = form.save!

      expect(permission).to have_attributes(workgroup: 'sdr:alpha', permission_type: 'edit',
                                            target_druid: 'druid:bc123df4567')
      expect(permission).to be_persisted
    end
  end
end
