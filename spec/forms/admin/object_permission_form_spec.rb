# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Admin::ObjectPermissionForm do
  let(:form) { described_class.new(workgroup: 'sdr:curators', permission_type: 'read_restricted') }

  it 'adds a Read permission for the supplied object' do
    expect(form.save(target_druid: 'druid:bc123df4567')).to be true
    expect(Permission.find_by(workgroup: 'sdr:curators', target_druid: 'druid:bc123df4567')&.permission_type)
      .to eq('read_restricted')
  end

  it 'adds an Edit permission' do
    form.permission_type = 'edit'
    expect(form.save(target_druid: 'druid:bc123df4567')).to be true
    expect(Permission.find_by(workgroup: 'sdr:curators', target_druid: 'druid:bc123df4567')&.permission_type)
      .to eq('edit')
  end

  it 'does not permit a target from the client' do
    expect(described_class.permitted_params).to eq(%i[workgroup permission_type])
  end

  context 'when the workgroup has surrounding whitespace' do
    let(:form) { described_class.new(workgroup: '  sdr:curators  ', permission_type: 'read_restricted') }

    it 'saves the canonical workgroup' do
      expect(form.save(target_druid: 'druid:bc123df4567')).to be true
      expect(Permission.where(target_druid: 'druid:bc123df4567').pluck(:workgroup)).to eq(['sdr:curators'])
    end

    it 'rejects a duplicate of the canonical workgroup' do
      create(:permission, :read_restricted, workgroup: 'sdr:curators', target_druid: 'druid:bc123df4567')
      expect { expect(form.save(target_druid: 'druid:bc123df4567')).to be false }
        .not_to change(Permission, :count)
      expect(form.errors[:workgroup]).to include('already has this permission')
    end
  end

  context 'when input is invalid' do
    it 'rejects a blank workgroup with feedback' do
      form.workgroup = ' '
      expect(form.save(target_druid: 'druid:bc123df4567')).to be false
      expect(form.errors[:workgroup]).to include("can't be blank")
    end

    ['admin', 'read_unrestricted', 'unknown', ''].each do |permission_type|
      it "rejects #{permission_type.inspect} with feedback" do
        form.permission_type = permission_type
        expect(form.save(target_druid: 'druid:bc123df4567')).to be false
        expect(form.errors[:permission_type]).to include('is not included in the list')
      end
    end
  end

  context 'when the permission already exists' do
    before do
      create(:permission, :read_restricted, workgroup: 'sdr:curators', target_druid: 'druid:bc123df4567')
    end

    it 'rejects the duplicate with feedback' do
      expect { expect(form.save(target_druid: 'druid:bc123df4567')).to be false }
        .not_to change(Permission, :count)
      expect(form.errors[:workgroup]).to include('already has this permission')
    end
  end
end
