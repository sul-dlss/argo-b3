# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ResultsSearchForm do
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
          page: 2
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

    context 'when only a facet operator is present' do
      subject(:form) { described_class.new(languages_operator: 'and') }

      it 'returns true' do
        expect(form.blank?).to be true
      end
    end
  end

  describe 'languages_operator' do
    it 'keeps And' do
      expect(described_class.new(languages_operator: 'and').languages_operator).to eq 'and'
    end

    it 'drops the default, Or' do
      expect(described_class.new(languages_operator: 'or').attributes).not_to have_key('languages_operator')
    end

    it 'drops an unknown operator' do
      expect(described_class.new(languages_operator: 'xor').attributes).not_to have_key('languages_operator')
    end
  end

  describe '#operator_for' do
    it 'returns the chosen operator' do
      expect(described_class.new(languages_operator: 'and').operator_for(Search::Facets::LANGUAGES)).to eq :and
    end

    it "returns the facet's default when no operator is chosen" do
      expect(described_class.new.operator_for(Search::Facets::LANGUAGES)).to eq :or
    end
  end

  describe '#with_attributes' do
    subject(:form) { described_class.new(query: 'test', object_types: ['DRO'], page: 1, projects: ['Google Books']) }

    let(:new_attrs) { { object_types: ['Collection'], page: 2, projects: nil } }

    it 'merges array attributes and overrides scalar attributes' do
      expect(form.with_attributes(new_attrs))
        .to eq({
                 'query' => 'test',
                 'object_types' => %w[DRO Collection],
                 'page' => 2,
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
        expect(form.selected?(key: 'debug')).to be false
      end

      it 'returns false for non-existent attributes' do
        expect(form.selected?(key: 'non_existent')).to be false
      end
    end
  end

  describe '#current_filters' do
    context 'when attributes are set' do
      subject(:form) { described_class.new(query: 'test') }

      it 'returns current filters as attribute name/values pairs' do
        expect(form.current_filters).to eq([['query', ['test']]])
      end
    end

    context 'when facet attributes are set' do
      it 'returns the current filters, grouping the values of checkbox facets' do
        expect(form.current_filters).to contain_exactly(
          ['query', ['test']],
          ['object_types', %w[item collection]],
          ['projects', ['Project 1']]
        )
      end
    end

    context 'when values are set for a checkbox facet combined with And' do
      subject(:form) { described_class.new(languages: %w[English Spanish], languages_operator: 'and') }

      it 'returns a single current filter for the values' do
        expect(form.current_filters).to eq([['languages', %w[English Spanish]]])
      end
    end

    context 'when multiple values are set for an ANDed facet' do
      subject(:form) { described_class.new(genres: %w[maps poetry]) }

      it 'returns a separate current filter for each value' do
        expect(form.current_filters).to eq([['genres', ['maps']], ['genres', ['poetry']]])
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
