# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SearchResults::FacetQueryCounts do
  let(:facet_counts) { described_class.new(solr_response:, field:) }
  let(:empty_facet_counts) { described_class.new(solr_response: empty_solr_response, field:) }

  let(:solr_response) do
    {
      'facet_counts' => {
        'facet_fields' => {
          'content_file_mimetypes_ssimdv' => [
            'image/jp2', 2_126_773,
            'image/tiff', 1_696_294,
            'image/jpeg', 463_129
          ]
        }
      }
    }
  end

  let(:empty_solr_response) do
    {
      'facet_counts' => {
        'facet_fields' => {
          'content_file_mimetypes_ssimdv' => []
        }
      }
    }
  end
  let(:field) { Search::Fields::MIMETYPES }

  describe '#each' do
    context 'when there are results' do
      it 'yields FacetCount objects' do
        yielded_values = facet_counts.map do |facet_count|
          {
            value: facet_count.value,
            count: facet_count.count
          }
        end

        expect(yielded_values).to eq([
                                       { value: 'image/jp2', count: 2_126_773 },
                                       { value: 'image/tiff', count: 1_696_294 },
                                       { value: 'image/jpeg', count: 463_129 }
                                     ])
      end
    end

    context 'when there are no results' do
      it 'yields nothing' do
        expect(empty_facet_counts.to_a).to be_empty
      end
    end
  end

  describe '#to_ary' do
    it 'returns an array of facet counts' do
      expect(facet_counts.to_ary).to be_an(Array)
      expect(facet_counts.to_ary.size).to eq(3)
    end
  end
end
