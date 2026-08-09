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
end
