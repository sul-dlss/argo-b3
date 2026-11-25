# frozen_string_literal: true

require 'rails_helper'

RSpec.describe StructuralCsv::AccessValidator do
  subject(:reasons) { described_class.call(row:) }

  let(:row) do
    csv_row = CSV::Row.new(%w[rights_view rights_download rights_location], [view, download, location])
    StructuralCsv::Row.new(number: 2, csv_row:)
  end
  let(:location) { '' }

  context 'when the access rights are valid' do
    let(:view) { 'location-based' }
    let(:download) { 'location-based' }
    let(:location) { 'spec' }

    it 'returns no reasons' do
      expect(reasons).to be_empty
    end
  end

  context 'when the view and download are not allowed' do
    let(:view) { 'stanfrod' }
    let(:download) { 'everyone' }

    it 'returns a reason for each, and not an invalid combination' do
      expect(reasons).to eq(
        [
          'Value for "rights_view" ("stanfrod") is not a valid view access',
          'Value for "rights_download" ("everyone") is not a valid download access'
        ]
      )
    end
  end

  context 'when the view is missing and the download is not allowed' do
    let(:view) { '' }
    let(:download) { 'everyone' }

    it 'returns a reason for the download, and not an invalid combination' do
      expect(reasons).to eq(['Value for "rights_download" ("everyone") is not a valid download access'])
    end
  end

  context 'when the view is missing and the download is location-based with a location that is not allowed' do
    let(:view) { '' }
    let(:download) { 'location-based' }
    let(:location) { 'moon' }

    it 'returns a reason for the location' do
      expect(reasons).to eq(['Value for "rights_location" ("moon") is not a valid location'])
    end
  end

  context 'when the view is missing and the download is allowed' do
    let(:view) { '' }
    let(:download) { 'world' }

    it 'returns no reasons, since the missing value is reported by Validator' do
      expect(reasons).to be_empty
    end
  end

  context 'when a location-based location is not allowed' do
    let(:view) { 'location-based' }
    let(:download) { 'none' }
    let(:location) { 'moon' }

    it 'returns a reason for the location' do
      expect(reasons).to eq(['Value for "rights_location" ("moon") is not a valid location'])
    end
  end

  context 'when a location is given for access that is not location-based' do
    let(:view) { 'world' }
    let(:download) { 'world' }
    let(:location) { 'moon' }

    it 'returns no reasons, since the location is not used' do
      expect(reasons).to be_empty
    end
  end

  context 'when the values are not a valid combination' do
    let(:view) { 'stanford' }
    let(:download) { 'world' }

    it 'returns a reason naming the values' do
      expect(reasons).to eq(
        ['Access rights (view "stanford", download "world", location blank) are not a valid combination']
      )
    end
  end
end
