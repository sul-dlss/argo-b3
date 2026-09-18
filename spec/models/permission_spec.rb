# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Permission do
  describe 'validations' do
    it 'is valid with a workgroup, an admin permission_type, and no target_druid' do
      permission = described_class.new(workgroup: 'sdr:administrator-role', permission_type: 'admin')
      expect(permission).to be_valid
    end

    it 'is valid with a workgroup, a read_unrestricted permission_type, and no target_druid' do
      permission = described_class.new(workgroup: 'sdr:administrator-role', permission_type: 'read_unrestricted')
      expect(permission).to be_valid
    end

    it 'is invalid when target_druid is not a valid druid' do
      permission = described_class.new(workgroup: 'sdr:administrator-role', permission_type: 'admin',
                                       target_druid: 'not-a-druid')
      expect(permission).not_to be_valid
      expect(permission.errors[:target_druid]).to include('is not a valid druid')
    end

    %w[read_restricted edit].each do |permission_type|
      context "when permission_type is #{permission_type}" do
        it 'is valid with a target_druid' do
          permission = described_class.new(workgroup: 'sdr:administrator-role', permission_type:,
                                           target_druid: 'druid:bc123df4567')
          expect(permission).to be_valid
        end

        it 'is invalid without a target_druid' do
          permission = described_class.new(workgroup: 'sdr:administrator-role', permission_type:)
          expect(permission).not_to be_valid
          expect(permission.errors[:target_druid])
            .to include("can't be blank for #{permission_type} permission type")
        end
      end
    end
  end

  describe 'events' do
    let(:user) { build_stubbed(:user, email_address: 'jdoe@stanford.edu') }
    let(:target_druid) { 'druid:bc123df4567' }
    let(:host) { 'argo-test.stanford.edu' }

    before do
      allow(Current).to receive(:user).and_return(user)
      allow(Socket).to receive(:gethostname).and_return(host)
      allow(Sdr::Event).to receive(:create)
    end

    context 'when a permission with a target druid is created' do
      it 'creates an event' do
        create(:permission, :edit, target_druid:)

        expect(Sdr::Event).to have_received(:create)
          .with(druid: target_druid, type: 'argo_permission_created',
                data: { who: 'jdoe', host:, permission_type: 'edit' })
      end
    end

    context 'when a permission with a target druid is destroyed' do
      let(:permission) { create(:permission, :edit, target_druid:) }

      it 'creates an event' do
        permission.destroy!

        expect(Sdr::Event).to have_received(:create)
          .with(druid: target_druid, type: 'argo_permission_deleted',
                data: { who: 'jdoe', host:, permission_type: 'edit' })
      end
    end

    context 'when the permission has no target druid' do
      it 'does not create an event' do
        create(:permission, :read_unrestricted).destroy!

        expect(Sdr::Event).not_to have_received(:create)
      end
    end

    context 'when there is no current user' do
      let(:user) { nil }

      it 'does not create an event' do
        create(:permission, :edit, target_druid:).destroy!

        expect(Sdr::Event).not_to have_received(:create)
      end
    end

    context 'when creating the event fails' do
      let(:permission) { described_class.new(workgroup: 'sdr:baker-staff', permission_type: 'edit', target_druid:) }

      before do
        allow(Sdr::Event).to receive(:create).and_raise(Sdr::Event::Error)
        allow(Honeybadger).to receive(:notify)
      end

      it 'saves the permission and notifies Honeybadger' do
        permission.save!

        expect(permission).to be_persisted
        expect(Honeybadger).to have_received(:notify)
      end
    end
  end
end
