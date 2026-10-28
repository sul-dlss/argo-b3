# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Search::YearRangeQuery do
  subject(:query) { described_class.call(facet_config: Search::Facets::DATES, search_form:) }

  let(:search_form) { ResultsSearchForm.new(dates_from: from, dates_to: to) }
  let(:years) { query.delete_prefix('{!terms f=publication_year_ssidv}').split(',') }

  context 'with from and to years' do
    let(:from) { '2000' }
    let(:to) { '2003' }

    it 'returns a terms query for each year in the range' do
      expect(query).to eq('{!terms f=publication_year_ssidv}2000,2001,2002,2003')
    end
  end

  context 'with negative (BCE) years' do
    let(:from) { '-2' }
    let(:to) { '1' }

    it 'returns a terms query for each year in the range' do
      expect(query).to eq('{!terms f=publication_year_ssidv}-2,-1,0,1')
    end
  end

  context 'with the same from and to year' do
    let(:from) { '1911' }
    let(:to) { '1911' }

    it 'returns a terms query for the year' do
      expect(query).to eq('{!terms f=publication_year_ssidv}1911')
    end
  end

  context 'with a from year after the to year' do
    let(:from) { '2002' }
    let(:to) { '2000' }

    it 'returns a terms query for the years between them' do
      expect(query).to eq('{!terms f=publication_year_ssidv}2000,2001,2002')
    end
  end

  context 'with only a from year' do
    let(:from) { '2000' }
    let(:to) { nil }

    it 'returns a terms query from the year through 9999' do
      expect(years.first).to eq('2000')
      expect(years.last).to eq('9999')
      expect(years.size).to eq(8000)
    end
  end

  context 'with only a to year' do
    let(:from) { nil }
    let(:to) { '-9000' }

    it 'returns a terms query from -9999 through the year' do
      expect(years.first).to eq('-9999')
      expect(years.last).to eq('-9000')
      expect(years.size).to eq(1000)
    end
  end

  context 'with years beyond -9999 and 9999' do
    let(:from) { '-2147483649' }
    let(:to) { '2147483648' }

    it 'limits the terms query to -9999 through 9999' do
      expect(years.first).to eq('-9999')
      expect(years.last).to eq('9999')
      expect(years.size).to eq(19_999)
    end
  end

  context 'with malformed years' do
    let(:from) { 'abc' }
    let(:to) { '2000x' }

    it 'returns nil' do
      expect(query).to be_nil
    end
  end

  context 'without from and to years' do
    let(:from) { nil }
    let(:to) { nil }

    it 'returns nil' do
      expect(query).to be_nil
    end
  end
end
