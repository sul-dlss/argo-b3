# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CocinaModels::DroPresenter do
  subject(:presenter) { described_class.new(cocina_model) }

  let(:cocina_model) do
    instance_double(
      CocinaModels::Dro,
      access_view:,
      access_download:,
      access_location:,
      location_based_access?: location_based_access?,
      location_based_download_access?: location_based_download_access?,
      embargo_release_date?: embargo_release_date?,
      embargo_view:,
      embargo_download:,
      embargo_location:,
      embargo_release_date:
    )
  end
  let(:access_view) { 'world' }
  let(:access_download) { 'none' }
  let(:access_location) { nil }
  let(:location_based_access?) { false }
  let(:location_based_download_access?) { false }
  let(:embargo_release_date?) { false }
  let(:embargo_view) { nil }
  let(:embargo_download) { nil }
  let(:embargo_location) { nil }
  let(:embargo_release_date) { nil }

  describe '#display_access_rights' do
    context 'when access is not location-based' do
      it 'returns the view and download values' do
        expect(presenter.display_access_rights).to eq('View: World, Download: None')
      end
    end

    context 'when view access is location-based' do
      let(:access_view) { 'location-based' }
      let(:access_download) { 'none' }
      let(:access_location) { 'stanford' }
      let(:location_based_access?) { true }

      it 'appends the location to view access' do
        expect(presenter.display_access_rights).to eq('View: Location (stanford), Download: None')
      end
    end

    context 'when download access is location-based' do
      let(:access_view) { 'stanford' }
      let(:access_download) { 'location-based' }
      let(:access_location) { 'stanford' }
      let(:location_based_download_access?) { true }

      it 'appends the location to download access' do
        expect(presenter.display_access_rights).to eq('View: Stanford, Download: Location (stanford)')
      end
    end
  end

  describe '#embargo' do
    context 'when there is no embargo' do
      it 'returns nil' do
        expect(presenter.embargo).to be_nil
      end
    end

    context 'when embargo is not location-based' do
      let(:embargo_release_date?) { true }
      let(:embargo_release_date) { Time.use_zone('Pacific Time (US & Canada)') { Time.zone.local(2026, 6, 1) } }
      let(:embargo_view) { 'world' }
      let(:embargo_download) { 'none' }

      it 'returns the embargo date with view and download values' do
        expect(presenter.embargo).to eq('June 01, 2026 12:00 AM - View: World, Download: None')
      end
    end

    context 'when embargo view is location-based' do
      let(:embargo_release_date?) { true }
      let(:embargo_release_date) { Time.use_zone('Pacific Time (US & Canada)') { Time.zone.local(2026, 6, 1) } }
      let(:embargo_view) { 'location-based' }
      let(:embargo_download) { 'none' }
      let(:embargo_location) { 'stanford' }

      it 'appends the location to the embargo view access' do
        expect(presenter.embargo).to eq('June 01, 2026 12:00 AM - View: Location (stanford), Download: None')
      end
    end

    context 'when embargo download is location-based' do
      let(:embargo_release_date?) { true }
      let(:embargo_release_date) { Time.use_zone('Pacific Time (US & Canada)') { Time.zone.local(2026, 6, 1) } }
      let(:embargo_view) { 'stanford' }
      let(:embargo_download) { 'location-based' }
      let(:embargo_location) { 'stanford' }

      it 'appends the location to the embargo download access' do
        expect(presenter.embargo).to eq('June 01, 2026 12:00 AM - View: Stanford, Download: Location (stanford)')
      end
    end
  end
end
