# frozen_string_literal: true

require 'rails_helper'

RSpec.describe YearType do
  subject(:year_type) { described_class.new }

  it 'casts integer strings to years' do
    expect(year_type.cast('2020')).to eq(2020)
    expect(year_type.cast('-10')).to eq(-10)
    expect(year_type.cast(' 1911 ')).to eq(1911)
    expect(year_type.cast(1999)).to eq(1999)
  end

  it 'casts blank and malformed values to nil' do
    expect(year_type.cast(nil)).to be_nil
    expect(year_type.cast('')).to be_nil
    expect(year_type.cast('abc')).to be_nil
    expect(year_type.cast('2000x')).to be_nil
    expect(year_type.cast('1e3')).to be_nil
    expect(year_type.cast('20.5')).to be_nil
  end

  it 'limits years to -9999 through 9999' do
    expect(year_type.cast('2147483648')).to eq(9999)
    expect(year_type.cast('-2147483649')).to eq(-9999)
  end

  it 'is registered as the year type' do
    expect(ActiveModel::Type.lookup(:year)).to be_a(described_class)
  end
end
