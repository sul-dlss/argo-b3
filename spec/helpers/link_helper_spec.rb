# frozen_string_literal: true

require 'rails_helper'

RSpec.describe LinkHelper do
  describe '#link_to_object' do
    it 'disables Turbo prefetching' do
      link = helper.link_to_object('An object', 'druid:bc123df4567', data: { turbo_frame: '_top' })

      expect(link).to include('href="/objects/druid:bc123df4567"')
      expect(link).to include('data-turbo-frame="_top"')
      expect(link).to include('data-turbo-prefetch="false"')
    end
  end

  describe '#link_to_new_tab' do
    it 'opens in a new tab and says so' do
      link = Capybara.string(helper.link_to_new_tab('SearchWorks', 'https://searchworks.stanford.edu/view/bc123df4567'))

      expect(link).to have_link('SearchWorks (opens in new tab)', href: 'https://searchworks.stanford.edu/view/bc123df4567')
      expect(link).to have_css('a[target="_blank"][rel="noopener"]')
      expect(link).to have_css('a i.bi-box-arrow-up-right[aria-hidden="true"]')
      expect(link).to have_css('a span.visually-hidden', text: '(opens in new tab)')
    end
  end

  describe '#link_to_purl' do
    it 'opens the PURL in a new tab' do
      link = Capybara.string(helper.link_to_purl('druid:bc123df4567'))

      expect(link).to have_link('View PURL page (opens in new tab)', href: "#{Settings.purl.url}/bc123df4567")
      expect(link).to have_css('a[target="_blank"] span.visually-hidden', text: '(opens in new tab)')
    end
  end

  describe '#searchworks_url' do
    let(:druid) { 'druid:bc123df4567' }

    context 'when a catalog record id is present' do
      it 'builds a url using the catalog record id' do
        expect(helper.searchworks_url(druid, 'a1234567')).to eq('https://searchworks.stanford.edu/view/a1234567')
      end
    end

    context 'when no catalog record id is present' do
      it 'builds a url using the druid' do
        expect(helper.searchworks_url(druid)).to eq('https://searchworks.stanford.edu/view/bc123df4567')
      end
    end
  end

  describe '#earthworks_url' do
    it 'builds a url using the bare druid' do
      expect(helper.earthworks_url('druid:bb014tx0752')).to eq('https://earthworks.stanford.edu/catalog/stanford-bb014tx0752')
    end
  end
end
