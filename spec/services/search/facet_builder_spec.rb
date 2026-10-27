# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Search::FacetBuilder do
  it 'builds the facet json' do
    expect(described_class.call(
             field: Search::Fields::PROJECTS_EXPLODED
           )).to eq({
                      type: 'terms',
                      field: Search::Fields::PROJECTS_EXPLODED,
                      sort: 'count',
                      numBuckets: true
                    })
  end

  context 'when alpha_sort is true' do
    it 'includes sort index in the facet json' do
      expect(described_class.call(
               field: Search::Fields::PROJECTS_EXPLODED,
               alpha_sort: true
             )).to include(sort: 'index')
    end
  end

  context 'when limit is provided' do
    it 'includes limit in the facet json' do
      expect(described_class.call(
               field: Search::Fields::PROJECTS_EXPLODED,
               limit: 5
             )).to include(limit: 5)
    end
  end

  context 'when prefix is provided' do
    it 'includes prefix in the facet json' do
      expect(described_class.call(
               field: Search::Fields::PROJECTS_EXPLODED,
               facet_prefix: 'Test'
             )).to include(prefix: 'Test')
    end
  end

  context 'when exclude is true' do
    it 'includes domain excludeTags in the facet json' do
      expect(described_class.call(
               field: Search::Fields::PROJECTS_EXPLODED,
               exclude: true
             )).to include(domain: { excludeTags: [Search::Fields::PROJECTS_EXPLODED] })
    end
  end

  context 'when missing_value is true' do
    it 'includes missing in the facet json' do
      expect(described_class.call(
               field: Search::Fields::LANGUAGES,
               missing_value: true
             )).to include(missing: true)
    end
  end
end
