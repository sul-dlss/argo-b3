# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Contents::ApplySelectedAccess do
  subject(:selected_cocina_object) { described_class.call(cocina_object:, params:) }

  let(:cocina_object) do
    embargo = { releaseDate: '2030-01-01T00:00:00Z', view: 'world', download: 'world' }
    build(:dro_with_metadata).new(access: { view: 'stanford', download: 'stanford', license:, embargo: })
  end
  let(:license) { 'https://creativecommons.org/publicdomain/zero/1.0/legalcode' }

  context 'without selected access' do
    let(:params) { {} }

    it 'returns the cocina object' do
      expect(selected_cocina_object).to be(cocina_object)
    end
  end

  context 'with selected access without an embargo' do
    let(:params) { { 'with_embargo' => 'false', 'access_view' => 'dark', 'access_download' => 'none' } }

    it 'replaces the access, retaining the rest of the access and the lock' do
      expect(selected_cocina_object.access).to have_attributes(view: 'dark', download: 'none', location: nil,
                                                               license:, embargo: nil)
      expect(selected_cocina_object.lock).to eq(cocina_object.lock)
    end
  end

  context 'with selected access with an embargo' do
    let(:params) do
      { 'with_embargo' => 'true', 'embargo_release_date' => '2040-06-01', 'access_view' => 'dark',
        'access_download' => 'none', 'embargo_view' => 'location-based', 'embargo_download' => 'location-based',
        'embargo_location' => 'spec' }
    end

    it 'replaces the access and the embargo' do
      expect(selected_cocina_object.access).to have_attributes(view: 'dark', download: 'none')
      expect(selected_cocina_object.access.embargo)
        .to have_attributes(releaseDate: DateTime.new(2040, 6, 1), view: 'location-based',
                            download: 'location-based', location: 'spec')
    end
  end

  context 'with an embargo selected without a release date' do
    let(:params) do
      { 'with_embargo' => 'true', 'access_view' => 'dark', 'access_download' => 'none',
        'embargo_view' => 'world', 'embargo_download' => 'world' }
    end

    it 'has an embargo, so that files get the access once the embargo ends' do
      expect(selected_cocina_object.access).to have_attributes(view: 'dark', download: 'none')
      expect(selected_cocina_object.access.embargo).to have_attributes(view: 'world', download: 'world')
      expect(Contents::DefaultFileAccess.new(cocina_object: selected_cocina_object).attributes)
        .to eq(view: 'world', download: 'world', location: nil)
    end
  end

  context 'with a selection that is not yet a valid combination' do
    # Location-based access requires a location.
    let(:params) { { 'with_embargo' => 'false', 'access_view' => 'location-based', 'access_download' => 'none' } }

    it 'does not validate it' do
      expect(selected_cocina_object.access).to have_attributes(view: 'location-based', location: nil)
    end
  end
end
