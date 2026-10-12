# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Admin::WorkgroupPermissionForm do
  let(:workgroup) { 'sdr:alpha' }

  let(:read_unrestricted_permissions) do
    Permission.permission_type_read_unrestricted.where(workgroup:, target_druid: nil)
  end

  describe '.permitted_params' do
    it 'does not permit the workgroup' do
      expect(described_class.permitted_params).to eq([:read_unrestricted])
    end
  end

  describe '.for_workgroup' do
    it 'is not read unrestricted when there is no permission' do
      expect(described_class.for_workgroup(workgroup).read_unrestricted).to be false
    end

    it 'is read unrestricted when the permission exists' do
      create(:permission, :read_unrestricted, workgroup:)

      expect(described_class.for_workgroup(workgroup).read_unrestricted).to be true
    end
  end

  describe '#valid?' do
    it 'requires a workgroup' do
      expect(described_class.new(workgroup: '')).not_to be_valid
    end
  end

  describe '#save' do
    it 'creates the permission when read unrestricted and none exists' do
      form = described_class.new(workgroup:, read_unrestricted: true)

      expect { expect(form.save).to be true }.to change(read_unrestricted_permissions, :count).from(0).to(1)
    end

    it 'does not create a duplicate permission' do
      create(:permission, :read_unrestricted, workgroup:)
      form = described_class.for_workgroup(workgroup)

      expect { form.save }.not_to change(read_unrestricted_permissions, :count)
    end

    it 'deletes the permission when not read unrestricted' do
      create(:permission, :read_unrestricted, workgroup:)
      form = described_class.new(workgroup:, read_unrestricted: false)

      expect { form.save }.to change(read_unrestricted_permissions, :count).from(1).to(0)
    end

    it 'returns false and changes nothing when invalid' do
      form = described_class.new(workgroup: '', read_unrestricted: true)

      expect { expect(form.save).to be false }.not_to(change(Permission, :count))
    end
  end

  describe '#additional_permissions' do
    it 'excludes the read unrestricted permission and other workgroups' do
      create(:permission, :read_unrestricted, workgroup:)
      edit_permission = create(:permission, :edit, workgroup:)
      create(:permission, :edit, workgroup: 'sdr:beta')

      expect(described_class.new(workgroup:).additional_permissions).to contain_exactly(edit_permission)
    end
  end
end
