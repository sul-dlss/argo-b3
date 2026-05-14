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
      location_based_download_access?: location_based_download_access?
    )
  end
  let(:access_location) { nil }
  let(:location_based_access?) { false }
  let(:location_based_download_access?) { false }

  describe '#display_access_rights' do
    context 'when access is not location-based' do
      let(:access_view) { 'world' }
      let(:access_download) { 'none' }

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
end
