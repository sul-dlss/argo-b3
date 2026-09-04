# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ObjectPolicy, type: :policy do
  subject(:policy) { described_class.new(record, user:) }

  let(:user) { create(:user, groups: ['sdr:object-editors']) }

  let(:object_druid) { generate(:unique_druid) }
  let(:collection_druid) { generate(:unique_druid) }
  let(:apo_druid) { generate(:unique_druid) }

  describe 'aliases' do
    let(:record) { {} }

    it 'resolves update? to edit?' do
      expect(policy.resolve_rule(:update?)).to eq(:edit?)
    end

    it 'resolves show_json? to show?' do
      expect(policy.resolve_rule(:show_json?)).to eq(:show?)
    end
  end

  describe '#edit?' do
    before do
      Current.effective_groups = user.groups
    end

    context 'with a Cocina-like record' do
      let(:record) do
        double(
          externalIdentifier: object_druid,
          structural:,
          administrative:
        )
      end
      let(:structural) { double(isMemberOf: [collection_druid]) }
      let(:administrative) { double(hasAdminPolicy: apo_druid) }

      context 'when there is an edit permission on the object' do
        before do
          Permission.create!(workgroup: 'sdr:object-editors', permission_type: :edit, target_druid: object_druid)
        end

        it 'authorizes edit' do
          expect(policy.apply(:edit?)).to be true
        end
      end

      context 'when there is an edit permission on the collection' do
        before do
          Permission.create!(workgroup: 'sdr:object-editors', permission_type: :edit, target_druid: collection_druid)
        end

        it 'authorizes edit' do
          expect(policy.apply(:edit?)).to be true
        end
      end

      context 'when there is an edit permission on the APO/admin policy' do
        before do
          Permission.create!(workgroup: 'sdr:object-editors', permission_type: :edit, target_druid: apo_druid)
        end

        it 'authorizes edit' do
          expect(policy.apply(:edit?)).to be true
        end
      end

      context 'when matching permission exists for a different group' do
        before do
          Permission.create!(workgroup: 'sdr:other-group', permission_type: :edit, target_druid: object_druid)
        end

        it 'denies edit' do
          expect(policy.apply(:edit?)).to be false
        end
      end

      context 'when no matching edit permissions exist' do
        it 'denies edit' do
          expect(policy.apply(:edit?)).to be false
        end
      end

      context 'when effective groups differ from user groups' do
        before do
          Current.effective_groups = ['sdr:other-group']
          Permission.create!(workgroup: 'sdr:other-group', permission_type: :edit, target_druid: object_druid)
        end

        it 'authorizes based on effective groups' do
          expect(policy.apply(:edit?)).to be true
        end
      end

      context 'when record values are unprefixed druids' do
        let(:record) do
          double(
            externalIdentifier: DruidSupport.bare_druid_from(object_druid),
            structural: double(isMemberOf: [DruidSupport.bare_druid_from(collection_druid)]),
            administrative: double(hasAdminPolicy: DruidSupport.bare_druid_from(apo_druid))
          )
        end

        before do
          Permission.create!(workgroup: 'sdr:object-editors', permission_type: :edit, target_druid: apo_druid)
        end

        it 'normalizes values and authorizes edit' do
          expect(policy.apply(:edit?)).to be true
        end
      end

      context 'when structural and administrative are missing values' do
        let(:structural) { nil }
        let(:administrative) { nil }

        before do
          Permission.create!(workgroup: 'sdr:object-editors', permission_type: :edit, target_druid: object_druid)
        end

        it 'still authorizes via object druid' do
          expect(policy.apply(:edit?)).to be true
        end
      end
    end

    context 'with a Solr presenter-like record using accessors' do
      let(:record) do
        double(
          druid: object_druid,
          collection_druids: [collection_druid],
          apo_druid:
        )
      end

      before do
        Permission.create!(workgroup: 'sdr:object-editors', permission_type: :edit, target_druid: collection_druid)
      end

      it 'uses accessor attributes to authorize edit' do
        expect(policy.apply(:edit?)).to be true
      end
    end

    context 'with a hash-like Solr document record' do
      let(:record) do
        {
          Search::Fields::ID => object_druid,
          Search::Fields::COLLECTION_DRUIDS => [collection_druid],
          Search::Fields::APO_DRUID => [apo_druid]
        }
      end

      before do
        Permission.create!(workgroup: 'sdr:object-editors', permission_type: :edit, target_druid: collection_druid)
      end

      it 'uses Solr field values to authorize edit' do
        expect(policy.apply(:edit?)).to be true
      end
    end

    context 'with Solr arrays and missing id' do
      let(:record) do
        {
          Search::Fields::COLLECTION_DRUIDS => [collection_druid],
          Search::Fields::APO_DRUID => [apo_druid, generate(:unique_druid)]
        }
      end

      before do
        Permission.create!(workgroup: 'sdr:object-editors', permission_type: :edit, target_druid: apo_druid)
      end

      it 'uses the first APO druid value' do
        expect(policy.apply(:edit?)).to be true
      end
    end

    context 'with a Cocina-like record that has no structural attribute (e.g., a Collection or AdminPolicy)' do
      let(:record) do
        double(
          externalIdentifier: object_druid,
          administrative:
        )
      end
      let(:administrative) { double(hasAdminPolicy: apo_druid) }

      context 'when there is an edit permission on the APO' do
        before do
          Permission.create!(workgroup: 'sdr:object-editors', permission_type: :edit, target_druid: apo_druid)
        end

        it 'authorizes edit without raising' do
          expect(policy.apply(:edit?)).to be true
        end
      end

      context 'when there is no matching edit permission' do
        it 'denies edit without raising' do
          expect(policy.apply(:edit?)).to be false
        end
      end
    end
  end

  describe '#show?' do
    let(:record) do
      {
        Search::Fields::ID => object_druid,
        Search::Fields::COLLECTION_DRUIDS => [collection_druid],
        Search::Fields::APO_DRUID => [apo_druid]
      }
    end

    context 'when the user has edit permission on the object collection and the APO is read restricted' do
      before do
        create(:permission, :edit, workgroup: 'sdr:object-editors', target_druid: collection_druid)
        create(:permission, :read_restricted, workgroup: 'sdr:other-group', target_druid: apo_druid)
      end

      it 'authorizes show because an updater is also a reader' do
        expect(policy.apply(:show?)).to be true
      end
    end

    context 'when the user has read restricted permission on the object' do
      before do
        create(:permission, :read_restricted, workgroup: 'sdr:object-editors', target_druid: object_druid)
      end

      it 'authorizes show' do
        expect(policy.apply(:show?)).to be true
      end
    end

    context 'when the user has read restricted permission on the object collection' do
      before do
        create(:permission, :read_restricted, workgroup: 'sdr:object-editors', target_druid: collection_druid)
      end

      it 'authorizes show' do
        expect(policy.apply(:show?)).to be true
      end
    end

    context 'when the user has read restricted permission on the object APO' do
      before do
        create(:permission, :read_restricted, workgroup: 'sdr:object-editors', target_druid: apo_druid)
      end

      it 'authorizes show' do
        expect(policy.apply(:show?)).to be true
      end
    end

    context 'when the user has read unrestricted permission and the object is not read restricted' do
      before do
        create(:permission, :read_unrestricted, workgroup: 'sdr:object-editors')
      end

      it 'authorizes show' do
        expect(policy.apply(:show?)).to be true
      end
    end

    context 'when the user has read unrestricted permission and the object is read restricted for another group' do
      before do
        create(:permission, :read_unrestricted, workgroup: 'sdr:object-editors')
        create(:permission, :read_restricted, workgroup: 'sdr:other-group', target_druid: collection_druid)
      end

      it 'denies show' do
        expect(policy.apply(:show?)).to be false
      end
    end

    context 'when the object belongs to both one restricted and one unrestricted collection' do
      let(:restricted_collection_druid) { 'druid:df234gh5678' }
      let(:unrestricted_collection_druid) { 'druid:hj345km6789' }
      let(:record) do
        {
          Search::Fields::ID => object_druid,
          Search::Fields::COLLECTION_DRUIDS => [restricted_collection_druid, unrestricted_collection_druid],
          Search::Fields::APO_DRUID => [apo_druid]
        }
      end

      context 'when an unrestricted reader does not have access to the restricted collection' do
        before do
          create(:permission, :read_unrestricted, workgroup: 'sdr:object-editors')
          create(:permission, :read_restricted,
                 workgroup: 'sdr:other-group', target_druid: restricted_collection_druid)
        end

        it 'denies show' do
          expect(policy.apply(:show?)).to be false
        end
      end

      context 'when an unrestricted reader has access to the restricted collection' do
        before do
          create(:permission, :read_unrestricted, workgroup: 'sdr:object-editors')
          create(:permission, :read_restricted,
                 workgroup: 'sdr:object-editors', target_druid: restricted_collection_druid)
        end

        it 'authorizes show' do
          expect(policy.apply(:show?)).to be true
        end
      end
    end

    context 'when the object belongs to collections restricted to different groups' do
      let(:second_collection_druid) { 'druid:np456qr7890' }
      let(:record) do
        {
          Search::Fields::ID => object_druid,
          Search::Fields::COLLECTION_DRUIDS => [collection_druid, second_collection_druid],
          Search::Fields::APO_DRUID => [apo_druid]
        }
      end

      before do
        create(:permission, :read_restricted, workgroup: 'sdr:object-editors', target_druid: collection_druid)
        create(:permission, :read_restricted,
               workgroup: 'sdr:other-group', target_druid: second_collection_druid)
      end

      it 'authorizes show when the user has access to one restricted collection' do
        expect(policy.apply(:show?)).to be true
      end
    end

    context 'when the user has read unrestricted permission and an unrelated object is read restricted' do
      before do
        create(:permission, :read_unrestricted, workgroup: 'sdr:object-editors')
        create(:permission, :read_restricted, workgroup: 'sdr:other-group')
      end

      it 'authorizes show' do
        expect(policy.apply(:show?)).to be true
      end
    end

    context 'when a matching read restricted permission exists for a different group' do
      before do
        create(:permission, :read_restricted, workgroup: 'sdr:other-group', target_druid: apo_druid)
      end

      it 'denies show' do
        expect(policy.apply(:show?)).to be false
      end
    end

    context 'when no matching permissions exist' do
      it 'denies show' do
        expect(policy.apply(:show?)).to be false
      end
    end
  end
end
