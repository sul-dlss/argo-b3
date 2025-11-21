# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Search::Form do
  subject(:form) { form_class.new(attributes) }

  # Need a few more attributes for testing purposes.
  let(:form_class) do
    Class.new(described_class) do
      attribute :object_types, array: true, default: -> { [] }
      attribute :projects, array: true, default: -> { [] }
      attribute :include_google_books, type: :boolean, default: false
      attribute :access_rights, array: true, default: -> { [] }
    end
  end

  describe '#blank?' do
    context 'when attributes are blank' do
      # Note that for Search::Form, "query" is the only non-ignored attribute.
      # However, subclasses may have additional attributes.
      let(:attributes) { { query: '', page: 2, include_google_books: true } }

      it 'returns true' do
        expect(form.blank?).to be true
      end
    end

    context 'when query is present' do
      let(:attributes) { { query: 'test' } }

      it 'returns false' do
        expect(form.blank?).to be false
      end
    end
  end

  describe '#with_attributes' do
    let(:attributes) { { query: 'test', object_types: ['DRO'], page: 1, projects: ['Google Books'] } }
    let(:new_attrs) { { object_types: ['Collection'], include_google_books: true, page: 2, projects: nil } }

    it 'merges array attributes and overrides scalar attributes' do
      expect(form.with_attributes(new_attrs))
        .to eq({
                 'query' => 'test',
                 'object_types' => %w[DRO Collection],
                 'page' => 2,
                 'include_google_books' => true,
                 'projects' => ['Google Books']
               })
    end
  end

  describe '#without_attributes' do
    let(:attributes) { { query: 'test', object_types: %w[item collection], page: 2, projects: ['Google Books'] } }
    let(:without_attrs) { { object_types: 'item', page: 2, projects: nil } }

    it 'removes specified attributes' do
      expect(form.without_attributes(without_attrs))
        .to eq({
                 'query' => 'test',
                 'object_types' => ['collection']
               })
    end
  end

  describe '#selected?' do
    let(:attributes) { { query: 'test', object_types: %w[DRO Collection], page: 2, projects: ['Google Books'] } }

    context 'when the key/value is selected' do
      it 'returns true for array attributes' do
        expect(form.selected?(key: 'object_types', value: 'DRO')).to be true
      end

      it 'returns true for array attributes when providing a symbol' do
        expect(form.selected?(key: 'object_types', value: :DRO)).to be true
      end

      it 'returns true for scalar attributes' do
        expect(form.selected?(key: 'page', value: 2)).to be true
      end
    end

    context 'when the key is selected' do
      it 'returns true for array attributes' do
        expect(form.selected?(key: 'object_types')).to be true
      end

      it 'returns true for scalar attributes' do
        expect(form.selected?(key: 'page')).to be true
      end
    end

    context 'when the key/value is not selected' do
      it 'returns false for array attributes' do
        expect(form.selected?(key: 'object_types', value: 'APO')).to be false
      end

      it 'returns false for scalar attributes' do
        expect(form.selected?(key: 'page', value: 1)).to be false
      end

      it 'returns false for non-existent attributes' do
        expect(form.selected?(key: 'non_existent', value: 'value')).to be false
      end
    end

    context 'when the key is not selected' do
      it 'returns false for array attributes' do
        expect(form.selected?(key: 'access_rights')).to be false
      end

      it 'returns false for scalar attributes' do
        expect(form.selected?(key: 'include_google_books')).to be false
      end

      it 'returns false for non-existent attributes' do
        expect(form.selected?(key: 'non_existent')).to be false
      end
    end
  end

  describe '#this_attributes' do
    let(:attributes) { { query: '', page: 2, include_google_books: true } }

    it 'returns empty array' do
      expect(form.this_attributes).to eq({})
    end
  end
end
