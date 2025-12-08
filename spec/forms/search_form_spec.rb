# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SearchForm do
  subject(:form) do
    described_class.new(
      object_types: %w[item collection],
      projects: ['Project 1'],
      query: 'test'
    )
  end

  describe '#facet_attributes' do
    it 'returns the attributes that correspond to facets' do
      expect(form.facet_attributes).to eq({
                                            'object_types' => %w[item collection],
                                            'projects' => ['Project 1']
                                          })
    end
  end

  describe '#blank?' do
    context 'when attributes are blank' do
      subject(:form) do
        described_class.new(
          query: '',
          page: 2,
          include_google_books: true
        )
      end

      it 'returns true' do
        expect(form.blank?).to be true
      end
    end

    context 'when query is present' do
      subject(:form) { described_class.new(query: 'test') }

      it 'returns false' do
        expect(form.blank?).to be false
      end
    end

    context 'when a facet attribute is present' do
      subject(:form) do
        described_class.new(
          object_types: ['DRO']
        )
      end

      it 'returns false' do
        expect(form.blank?).to be false
      end
    end
  end

  describe '#with_attributes' do
    subject(:form) { described_class.new(query: 'test', object_types: ['DRO'], page: 1, projects: ['Google Books']) }

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
    subject(:form) do
      described_class.new(query: 'test', object_types: %w[item collection], page: 2, projects: ['Google Books'])
    end

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
    subject(:form) do
      described_class.new(query: 'test', object_types: %w[DRO Collection], page: 2, projects: ['Google Books'])
    end

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

  describe '#current_filters' do
    context 'when attributes are set' do
      subject(:form) { described_class.new(query: 'test', include_google_books: true) }

      it 'returns current filters as attribute name/value pairs' do
        expect(form.current_filters).to eq([%w[query test], ['include_google_books', true]])
      end
    end

    context 'when facet attributes are set' do
      it 'returns the current filters as attribute name/value pairs' do
        expect(form.current_filters).to contain_exactly(
          %w[query test],
          %w[object_types item],
          %w[object_types collection],
          ['projects', 'Project 1']
        )
      end
    end

    context 'when no attributes are set' do
      subject(:form) { described_class.new }

      it 'returns empty array' do
        expect(form.current_filters).to eq([])
      end
    end
  end

  describe '#facets_selected?' do
    context 'when no facets are selected' do
      subject(:form) { described_class.new(query: 'test') }

      it 'returns false' do
        expect(form.facets_selected?).to be false
      end
    end

    context 'when a facet is selected' do
      subject(:form) { described_class.new(object_types: ['DRO']) }

      it 'returns true' do
        expect(form.facets_selected?).to be true
      end
    end
  end

  describe '#to_s' do
    subject(:form) { described_class.new(query: 'test') }

    it 'returns the serialized search form' do
      expect(form.to_s).to eq('"test"')
    end
  end
end
