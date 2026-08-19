# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ObjectPolicy, type: :policy do
  subject(:policy) { described_class.new(record, user:) }

  let(:user) { create(:user, groups: ['sdr:object-editors']) }
  let(:other_group_user) { create(:user, groups: ['sdr:other-group']) }

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
  end

  describe '#show?' do
    let(:record) { {} }

    it 'allows show for the primary user' do
      expect(policy.apply(:show?)).to be true
    end

    it 'allows show for another user' do
      other_user_policy = described_class.new(record, user: other_group_user)

      expect(other_user_policy.apply(:show?)).to be true
    end
  end
end
