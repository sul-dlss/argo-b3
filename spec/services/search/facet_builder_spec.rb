# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Search::FacetBuilder do
  it 'builds the facet json' do
    expect(described_class.call(
             field: Search::Fields::PROJECT_TAGS
           )).to eq({
                      type: 'terms',
                      field: Search::Fields::PROJECT_TAGS,
                      sort: 'count',
                      numBuckets: true
                    })
  end

  context 'when alpha_sort is true' do
    it 'includes sort index in the facet json' do
      expect(described_class.call(
               field: Search::Fields::PROJECT_TAGS,
               alpha_sort: true
             )).to include(sort: 'index')
    end
  end

  context 'when limit is provided' do
    it 'includes limit in the facet json' do
      expect(described_class.call(
               field: Search::Fields::PROJECT_TAGS,
               limit: 5
             )).to include(limit: 5)
    end
  end

  context 'when prefix is provided' do
    it 'includes prefix in the facet json' do
      expect(described_class.call(
               field: Search::Fields::PROJECT_TAGS,
               facet_prefix: 'Test'
             )).to include(prefix: 'Test')
    end
  end

  context 'when exclude is true' do
    it 'includes domain excludeTags in the facet json' do
      expect(described_class.call(
               field: Search::Fields::PROJECT_TAGS,
               exclude: true
             )).to include(domain: { excludeTags: [Search::Fields::PROJECT_TAGS] })
    end
  end
end
