# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PinnedSearch do
  let(:user) { create(:user) }
  let(:search_form) { SearchForm.new(query: 'test', object_types: %w[collection item]) }

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
      expect(pinned_search.search_form_md5).to eq(Digest::MD5.hexdigest(search_form.attributes.to_json))
    end
  end

  describe '.exists?' do
    before do
      described_class.create_from_search_form(search_form:, user:)
    end

    it 'returns true when the search is pinned by the user' do
      expect(described_class.exists?(search_form:, user:)).to be true
    end

    it 'returns false when the search is not pinned by the user' do
      expect(described_class.exists?(search_form:, user: create(:user))).to be false
    end

    it 'returns false when a different search is pinned by the user' do
      different_search_form = SearchForm.new(query: 'different')

      expect(described_class.exists?(search_form: different_search_form, user:)).to be false
    end
  end

  describe '#to_search_form' do
    subject(:restored_search_form) do
      create(:pinned_search, search_form_attributes: search_form.attributes).to_search_form
    end

    it 'returns the stored attributes as a search form' do
      expect(restored_search_form).to be_a(SearchForm)
      expect(restored_search_form.attributes).to eq(search_form.attributes)
    end
  end
end
