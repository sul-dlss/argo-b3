# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PinnedSearch do
  let(:user) { create(:user) }
  let(:search_form) { ResultsSearchForm.new(query: 'test', object_types: %w[collection item]) }

  describe 'validations' do
    subject(:pinned_search) { described_class.new(user:) }

    it 'requires search form attributes' do
      expect(pinned_search).not_to be_valid
      expect(pinned_search.errors[:search_form_attributes]).to include("can't be blank")
    end
  end

  describe '.create_from_search_form' do
    subject(:pinned_search) { described_class.create_from_search_form(search_form:, user:) }

    it 'creates a pinned search from the search form' do
      expect(pinned_search).to be_persisted
      expect(pinned_search.user).to eq(user)
      expect(pinned_search.search_form_attributes).to eq(search_form.attributes)
      expect(pinned_search.search_form_md5).to eq(described_class.md5_for(search_form.attributes))
    end
  end

  describe '.exists_by_search_form?' do
    before do
      described_class.create_from_search_form(search_form:, user:)
    end

    it 'returns true when the search is pinned by the user' do
      expect(described_class.exists_by_search_form?(search_form:, user:)).to be true
    end

    it 'returns false when the search is not pinned by the user' do
      expect(described_class.exists_by_search_form?(search_form:, user: create(:user))).to be false
    end

    it 'returns false when a different search is pinned by the user' do
      different_search_form = ResultsSearchForm.new(query: 'different')

      expect(described_class.exists_by_search_form?(search_form: different_search_form, user:)).to be false
    end
  end

  describe '.md5_for' do
    # The digest is what identifies a pinned search, and it is computed from a hash whose key order
    # is not stable: it follows the form class's attribute declaration order in memory, but jsonb
    # reorders keys on storage. Sorting makes the digest independent of both.
    it 'does not depend on the order of the attributes' do
      attributes = { 'query' => 'test', 'object_types' => %w[collection item] }

      expect(described_class.md5_for(attributes)).to eq(described_class.md5_for(attributes.reverse_each.to_h))
    end

    it 'differs for different searches' do
      expect(described_class.md5_for({ 'query' => 'test' })).not_to eq(described_class.md5_for({ 'query' => 'other' }))
    end

    it 'recognizes a pinned search after the attributes have been through the database' do
      described_class.create_from_search_form(search_form:, user:)
      reread = described_class.find_by!(user:, search_form_md5: described_class.md5_for(search_form.attributes))

      expect(described_class.md5_for(reread.search_form_attributes)).to eq(reread.search_form_md5)
    end
  end

  describe '#to_search_form' do
    subject(:restored_search_form) do
      create(:pinned_search, search_form_attributes: search_form.attributes).to_search_form
    end

    it 'returns the stored attributes as a search form' do
      expect(restored_search_form).to be_a(ResultsSearchForm)
      expect(restored_search_form.attributes).to eq(search_form.attributes)
    end
  end
end
