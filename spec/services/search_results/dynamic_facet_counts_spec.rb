# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SearchResults::DynamicFacetCounts do
  let(:facet_counts) { described_class.new(solr_response:, facet_config: Search::Facets::RELEASED_TO_EARTHWORKS) }

  let(:solr_response) do
    {

      'facets' => {
        'released_to_earthworks-last_week' => {
          'count' => 0
        },
        'released_to_earthworks-last_month' => {
          'count' => 0
        },
        'released_to_earthworks-last_year' => {
          'count' => 306
        },
        'released_to_earthworks-ever' => {
          'count' => 28_858
        },
        'released_to_earthworks-never' => {
          'count' => 2_417_690
        }
      }
    }
  end

  describe '#each' do
    context 'when there are facet counts' do
      it 'yields FacetCount objects' do
        yielded_values = facet_counts.map do |facet_count|
          {
            value: facet_count.value,
            count: facet_count.count
          }
        end

        expect(yielded_values).to eq([
                                       { value: 'last_week', count: 0 },
                                       { value: 'last_month', count: 0 },
                                       { value: 'last_year', count: 306 },
                                       { value: 'ever', count: 28_858 },
                                       { value: 'never', count: 2_417_690 }
                                     ])
      end
    end

    context 'when there are no facet counts' do
      let(:solr_response) do
        {
          'facets' => { 'count' => 0, 'objectType_ssimdv' => { 'numBuckets' => 0, 'buckets' => [] } }
        }
      end

      it 'yields nothing' do
        expect(facet_counts.to_a).to be_empty
      end
    end
  end

  describe '#to_ary' do
    it 'returns an array of facet counts' do
      expect(facet_counts.to_ary).to be_an(Array)
      expect(facet_counts.to_ary.size).to eq(5)
    end
  end
end
