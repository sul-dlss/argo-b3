# frozen_string_literal: true

require 'rails_helper'

RSpec.describe LinkHelper do
  describe '#searchworks_url' do
    let(:druid) { 'druid:bc123df4567' }

    context 'when a catalog record id is present' do
      it 'builds a url using the catalog record id' do
        expect(helper.searchworks_url(druid, 'a1234567')).to eq('https://searchworks.stanford.edu/view/a1234567')
      end
    end

    context 'when no catalog record id is present' do
      it 'builds a url using the druid' do
        expect(helper.searchworks_url(druid)).to eq("https://searchworks.stanford.edu/view/#{druid}")
      end
    end
  end

  describe '#earthworks_url' do
    it 'builds a url using the bare druid' do
      expect(helper.earthworks_url('druid:bb014tx0752')).to eq('https://earthworks.stanford.edu/catalog/stanford-bb014tx0752')
    end
  end
end
