# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ItemPolicy do
  subject(:policy) { described_class.new(user:) }

  describe '#new?' do
    subject { policy.apply(:new?) }

    let(:user) { create(:user, groups: [workgroup]) }
    let(:workgroup) { 'sdr:test-workgroup' }

    before do
      Current.effective_groups = user.groups
    end

    context 'when the user belongs to a workgroup with edit permission' do
      before do
        create(:permission, :edit, workgroup:)
      end

      it { is_expected.to be true }
    end

    context 'when the user does not belong to a workgroup with edit permission' do
      it { is_expected.to be false }
    end

    context 'when the effective groups differ from user groups' do
      before do
        Current.effective_groups = ['sdr:effective-group']
        create(:permission, :edit, workgroup: 'sdr:effective-group')
      end

      it { is_expected.to be true }
    end
  end

  describe '#create?' do
    subject { described_class.new(record, user:).apply(:create?) }

    let(:user) { create(:user, groups: [workgroup]) }
    let(:workgroup) { 'sdr:test-workgroup' }
    let(:apo_druid) { 'druid:bc123df4567' }
    let(:collection_druid) { 'druid:gh456jk7890' }
    let(:collection_apo_druid) { 'druid:mn789pq0123' }
    let(:collection_druids) { [] }
    let(:record) { NewItemForm.new(apo_druid:, collection_druids:) }
    let(:collection_solr_doc) do
      { Search::Fields::ID => collection_druid, Search::Fields::APO_DRUID => [collection_apo_druid] }
    end

    before do
      Current.effective_groups = user.groups
      allow(Sdr::Repository).to receive(:find_solr).with(druid: collection_druid).and_return(collection_solr_doc)
    end

    context 'when the user is an admin' do
      let(:user) { create(:user, :admin) }
      let(:collection_druids) { [collection_druid] }

      it { is_expected.to be true }
    end

    context 'when the user has edit permission for the APO' do
      before { create(:permission, :edit, workgroup:, target_druid: apo_druid) }

      it { is_expected.to be true }

      context 'when the user has edit permission for the collection' do
        let(:collection_druids) { [collection_druid] }

        before { create(:permission, :edit, workgroup:, target_druid: collection_druid) }

        it { is_expected.to be true }
      end

      context "when the user has edit permission for the collection's APO" do
        let(:collection_druids) { [collection_druid] }

        before { create(:permission, :edit, workgroup:, target_druid: collection_apo_druid) }

        it { is_expected.to be true }
      end

      context 'when the user does not have edit permission for the collection' do
        let(:collection_druids) { [collection_druid] }

        before { create(:permission, :read_restricted, workgroup:, target_druid: collection_druid) }

        it { is_expected.to be false }
      end

      context 'when the collection is not found' do
        let(:collection_druids) { [collection_druid] }

        before do
          allow(Sdr::Repository).to receive(:find_solr).with(druid: collection_druid)
                                                       .and_raise(Sdr::Repository::NotFoundResponse)
        end

        it { is_expected.to be false }
      end
    end

    context 'when the user does not have edit permission for the APO' do
      let(:collection_druids) { [collection_druid] }

      before { create(:permission, :edit, workgroup:, target_druid: collection_druid) }

      it { is_expected.to be false }
    end

    context 'when no APO is selected' do
      let(:apo_druid) { nil }

      context 'when the user has edit permission for the collection' do
        let(:collection_druids) { [collection_druid] }

        before { create(:permission, :edit, workgroup:, target_druid: collection_druid) }

        it { is_expected.to be true }
      end

      context 'when the user has no edit permission' do
        it { is_expected.to be false }
      end
    end
  end

  describe '#add_to_collections?' do
    subject(:policy_result) { described_class.new(item_model, user:).apply(:add_to_collections?) }

    let(:item_model) do
      CocinaModels::Factory.build(build(:dro_with_metadata, collection_ids: member_collection_druids)).tap do |model|
        model.collection_druids = collection_druids
      end
    end
    let(:member_collection_druids) { [] }
    let(:user) { create(:user, groups: [workgroup]) }
    let(:workgroup) { 'sdr:test-workgroup' }
    let(:collection_druid) { 'druid:gh456jk7890' }
    let(:collection_apo_druid) { 'druid:mn789pq0123' }
    let(:collection_druids) { [collection_druid] }
    let(:collection_solr_doc) do
      { Search::Fields::ID => collection_druid, Search::Fields::APO_DRUID => [collection_apo_druid] }
    end

    before do
      Current.effective_groups = user.groups
      allow(Sdr::Repository).to receive(:find_solr).with(druid: collection_druid).and_return(collection_solr_doc)
    end

    context 'when the user has edit permission for the collection' do
      before { create(:permission, :edit, workgroup:, target_druid: collection_druid) }

      it { is_expected.to be true }
    end

    context "when the user has edit permission for the collection's APO" do
      before { create(:permission, :edit, workgroup:, target_druid: collection_apo_druid) }

      it { is_expected.to be true }
    end

    context 'when the user does not have edit permission for the collection' do
      before { create(:permission, :read_restricted, workgroup:, target_druid: collection_druid) }

      it { is_expected.to be false }
    end

    context 'when the collection is not found' do
      before do
        create(:permission, :edit, workgroup:, target_druid: collection_apo_druid)
        allow(Sdr::Repository).to receive(:find_solr).with(druid: collection_druid)
                                                     .and_raise(Sdr::Repository::NotFoundResponse)
      end

      it { is_expected.to be false }
    end

    context 'when there are no collections' do
      let(:collection_druids) { [] }

      it { is_expected.to be true }
    end

    context 'when the item is already a member of a collection that the user cannot edit' do
      let(:member_collection_druids) { [collection_druid] }

      it 'allows keeping the collection' do
        expect(policy_result).to be true
        expect(Sdr::Repository).not_to have_received(:find_solr)
      end
    end
  end

  describe '#update_apo?' do
    subject { described_class.new(item_model, user:).apply(:update_apo?) }

    let(:item_model) do
      CocinaModels::Factory.build(build(:dro_with_metadata, admin_policy_id: current_apo_druid)).tap do |model|
        model.apo_druid = apo_druid
      end
    end
    let(:user) { create(:user, groups: [workgroup]) }
    let(:workgroup) { 'sdr:test-workgroup' }
    let(:current_apo_druid) { 'druid:bc123df4567' }
    let(:apo_druid) { 'druid:gh456jk7890' }

    before { Current.effective_groups = user.groups }

    context 'when the user has edit permission for the new APO' do
      before { create(:permission, :edit, workgroup:, target_druid: apo_druid) }

      it { is_expected.to be true }
    end

    context 'when the user does not have edit permission for the new APO' do
      before { create(:permission, :read_restricted, workgroup:, target_druid: apo_druid) }

      it { is_expected.to be false }
    end

    context 'when the APO is unchanged' do
      let(:apo_druid) { current_apo_druid }

      it { is_expected.to be true }
    end
  end
end
