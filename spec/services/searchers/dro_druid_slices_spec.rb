# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Searchers::DroDruidSlices do
  subject(:druid_slices) { described_class.new(slice_size: 2) }

  before do
    allow(Search::SolrService).to receive(:post).and_return(
      solr_response(druids: ['druid:bc123df4567', 'druid:hj456km7891', 'druid:mn789pq0123'], next_cursor_mark: 'mark1',
                    num_found: 4),
      solr_response(druids: ['druid:rs234tv5678'], next_cursor_mark: 'mark2', num_found: 5),
      solr_response(druids: [], next_cursor_mark: 'mark2', num_found: 5)
    )
  end

  def solr_response(druids:, next_cursor_mark:, num_found:)
    {
      'response' => { 'numFound' => num_found, 'docs' => druids.map { |druid| { 'id' => druid } } },
      'nextCursorMark' => next_cursor_mark
    }
  end

  it 'returns slices of the DRO druids, paging through Solr, then nil' do
    expect(Array.new(4) { druid_slices.next }).to eq([['druid:bc123df4567', 'druid:hj456km7891'],
                                                      ['druid:mn789pq0123'],
                                                      ['druid:rs234tv5678'],
                                                      nil])
    expect(Search::SolrService).to have_received(:post).with(
      request: { q: '*:*', fq: ['objectType_ssimdv:(item OR agreement OR "virtual object")'], fl: ['id'],
                 sort: 'id asc', rows: 1000, cursorMark: '*' }
    )
    expect(Search::SolrService).to have_received(:post).with(request: hash_including(cursorMark: 'mark1'))
    expect(Search::SolrService).to have_received(:post).with(request: hash_including(cursorMark: 'mark2'))
  end

  it 'does not query Solr again after the last page' do
    Array.new(5) { druid_slices.next }

    expect(Search::SolrService).to have_received(:post).exactly(3).times
  end

  it 'has the number of DROs as of the first page' do
    Array.new(4) { druid_slices.next }

    expect(druid_slices.total_count).to eq(4)
  end

  context 'with a limit' do
    subject(:druid_slices) { described_class.new(slice_size: 2, limit: 3) }

    it 'returns only the first druids, without querying Solr after reaching the limit' do
      expect(Array.new(3) { druid_slices.next }).to eq([['druid:bc123df4567', 'druid:hj456km7891'],
                                                        ['druid:mn789pq0123'],
                                                        nil])
      expect(druid_slices.total_count).to eq(3)
      expect(Search::SolrService).to have_received(:post).once
    end
  end

  context 'with a limit larger than the number of DROs' do
    subject(:druid_slices) { described_class.new(slice_size: 2, limit: 10) }

    it 'returns all of the druids' do
      expect(Array.new(4) { druid_slices.next }.compact.flatten.size).to eq(4)
      expect(druid_slices.total_count).to eq(4)
    end
  end
end
