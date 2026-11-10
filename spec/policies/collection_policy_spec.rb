# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CollectionPolicy do
  let(:user) { create(:user, groups: [workgroup]) }
  let(:workgroup) { 'sdr:test-workgroup' }
  let(:apo_druid) { 'druid:bc123df4567' }

  before { Current.effective_groups = user.groups }

  describe '#new?' do
    subject { described_class.new(user:).apply(:new?) }

    context 'when the user is an admin' do
      let(:user) { create(:user, :admin) }

      it { is_expected.to be true }
    end

    context 'when the user belongs to a workgroup with edit permission' do
      before { create(:permission, :edit, workgroup:, target_druid: apo_druid) }

      it { is_expected.to be true }
    end

    context 'when the user does not belong to a workgroup with edit permission' do
      before { create(:permission, :read_restricted, workgroup:, target_druid: apo_druid) }

      it { is_expected.to be false }
    end
  end

  describe '#create?' do
    subject { described_class.new(apo_druid, user:).apply(:create?) }

    context 'when the user is an admin' do
      let(:user) { create(:user, :admin) }

      it { is_expected.to be true }
    end

    context 'when the user belongs to a workgroup with edit permission for the selected APO' do
      before { create(:permission, :edit, workgroup:, target_druid: apo_druid) }

      it { is_expected.to be true }
    end

    context 'when the user belongs to a workgroup with edit permission for a different APO' do
      before { create(:permission, :edit, workgroup:, target_druid: 'druid:xy987zw6543') }

      it { is_expected.to be false }
    end

    context 'when the user belongs to a workgroup with read permission for the selected APO' do
      before { create(:permission, :read_restricted, workgroup:, target_druid: apo_druid) }

      it { is_expected.to be false }
    end

    context 'when no APO is selected' do
      subject { described_class.new('', user:).apply(:create?) }

      context 'when the user belongs to a workgroup with edit permission' do
        before { create(:permission, :edit, workgroup:, target_druid: 'druid:xy987zw6543') }

        it { is_expected.to be true }
      end

      context 'when the user does not belong to a workgroup with edit permission' do
        it { is_expected.to be false }
      end
    end
  end

  describe '#update_apo?' do
    subject { described_class.new(collection_model, user:).apply(:update_apo?) }

    let(:collection_model) do
      EditCollectionForm.build_from_cocina_object(
        build(:collection_with_metadata, admin_policy_id: current_apo_druid)
      ).tap { |model| model.apo_druid = new_apo_druid }
    end
    let(:current_apo_druid) { apo_druid }
    let(:new_apo_druid) { 'druid:gh456jk7890' }

    context 'when the user is an admin' do
      let(:user) { create(:user, :admin) }

      it { is_expected.to be true }
    end

    context 'when the user has edit permission for the new APO' do
      before { create(:permission, :edit, workgroup:, target_druid: new_apo_druid) }

      it { is_expected.to be true }
    end

    context 'when the user has edit permission only for the current APO' do
      before { create(:permission, :edit, workgroup:, target_druid: current_apo_druid) }

      it { is_expected.to be false }
    end

    context 'when the APO is unchanged' do
      let(:new_apo_druid) { current_apo_druid }

      it { is_expected.to be true }
    end
  end
end
