# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SearchResults::Item do
  let(:item) { described_class.new(solr_doc:, index: 2) }
  let(:solr_doc) do
    {
      Search::Fields::PROJECTS => ['Rigler-Deutsch Index'],
      Search::Fields::ID => 'druid:rt276nw8963',
      Search::Fields::APO_DRUID => ['druid:bz845pv2292'],
      Search::Fields::OBJECT_TYPES => ['item'],
      Search::Fields::TITLE => 'Mark Twain : portrait for orchestra',
      Search::Fields::CONTENT_TYPES => ['image'],
      Search::Fields::APO_TITLE => ['ARS'],
      Search::Fields::BARE_DRUID => 'rt276nw8963'
    }
  end

  describe '#id' do
    it 'returns the id from the solr document' do
      expect(item.id).to eq('druid:rt276nw8963')
    end
  end

  describe '#title (method missing)' do
    it 'returns the title from the solr document' do
      expect(item.title).to eq('Mark Twain : portrait for orchestra')
    end
  end

  describe '#index' do
    it 'returns the index' do
      expect(item.index).to eq(2)
    end
  end

  describe '#apo_druid' do
    it 'returns the apo_druid from the solr document' do
      expect(item.apo_druid).to eq('druid:bz845pv2292')
    end
  end

  describe '#apo_title' do
    it 'returns the apo_title from the solr document' do
      expect(item.apo_title).to eq('ARS')
    end
  end
end
