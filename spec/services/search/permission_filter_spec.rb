# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Search::PermissionFilter, :solr do
  let(:user) { create(:user) }
  let(:apo_druid) { 'druid:bc123df4567' }
  let(:collection_druid) { 'druid:df234gh5678' }
  let(:other_collection_druid) { 'druid:hj345km6789' }
  let(:object_druid) { 'druid:np456qr7890' }
  # Drives both sides of the comparison: `user_scope` for the filter under test, and
  # `Current.effective_groups` for the ObjectPolicy the filter is asserted to agree with.
  let(:effective_groups) { user.groups }
  let(:user_scope) { Permissions::UserScope.new(groups: Array(effective_groups)) }
  let(:documents) do
    [
      build(:solr_item, druid: object_druid, apo_druid:,
                        collection_druids: [collection_druid, other_collection_druid]),
      build(:solr_item, druid: collection_druid, apo_druid:, collection_druids: [], object_type: 'collection'),
      build(:solr_item, druid: apo_druid, collection_druids: [], object_type: 'APO'),
      build(:solr_item, druid: 'druid:rs567tv8901', collection_druids: [])
    ]
  end

  before do
    Current.effective_groups = effective_groups
    Search::SolrFactory.call.add(documents)
    Search::SolrFactory.call.commit
  end

  shared_examples 'the object policy scope' do
    it 'matches exactly the documents authorized by ObjectPolicy' do
      expected_ids = documents.select { |document| ObjectPolicy.new(document, user:).apply(:show?) }
                              .pluck(Search::Fields::ID)
      response = Search::SolrService.post(request: { q: '*:*', fq: [described_class.call(user_scope:)].compact })

      expect(response.fetch('response').fetch('docs').pluck(Search::Fields::ID)).to match_array(expected_ids)
      expect(response.fetch('response').fetch('numFound')).to eq(expected_ids.size)
    end
  end

  context 'without permissions' do
    it_behaves_like 'the object policy scope'
  end

  context 'without effective groups' do
    let(:user) { create(:user, :admin) }
    let(:effective_groups) { nil }

    it 'fails closed' do
      response = Search::SolrService.post(request: { q: '*:*', fq: described_class.call(user_scope:) })

      expect(response.fetch('response').fetch('numFound')).to eq(0)
    end
  end

  context 'when an administrator' do
    let(:user) { create(:user, :admin) }

    it_behaves_like 'the object policy scope'
  end

  %i[object_druid collection_druid apo_druid].product(%i[edit read_restricted]).each do |target, permission_type|
    context "with #{permission_type} on #{target}" do
      before do
        create(:permission, permission_type, workgroup: user.groups.first, target_druid: public_send(target))
        create(:permission, :read_restricted, workgroup: 'sdr:other-group', target_druid: other_collection_druid)
      end

      it_behaves_like 'the object policy scope'
    end
  end

  context 'when an unrestricted reader' do
    let(:user) { create(:user, :reader) }

    it_behaves_like 'the object policy scope'

    context 'with a restriction on any target' do
      before do
        create(:permission, :read_restricted, workgroup: 'sdr:other-group', target_druid: collection_druid)
      end

      it_behaves_like 'the object policy scope'

      context 'with a matching grant on a different target' do
        before do
          create(:permission, :read_restricted, workgroup: user.groups.first, target_druid: apo_druid)
        end

        it_behaves_like 'the object policy scope'
      end
    end
  end

  context 'when impersonating a restricted reader' do
    let(:user) { create(:user, :admin) }
    let(:effective_groups) { ['sdr:impersonated'] }

    before do
      create(:permission, :read_restricted, workgroup: 'sdr:impersonated', target_druid: collection_druid)
    end

    it_behaves_like 'the object policy scope'

    it 'does not inherit administrator access' do
      response = Search::SolrService.post(request: { q: '*:*', fq: described_class.call(user_scope:) })

      expect(response.fetch('response').fetch('docs').pluck(Search::Fields::ID))
        .to contain_exactly(object_druid, collection_druid)
    end
  end
end
