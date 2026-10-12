# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Contents::DefaultFileAccess do
  subject(:default_file_access) { described_class.new(cocina_object:) }

  let(:cocina_object) { build(:dro).new(access:) }

  context 'when world' do
    let(:access) { { view: 'world', download: 'world' } }

    it 'has the object access and is not dark' do
      expect(default_file_access.attributes).to eq({ view: 'world', download: 'world', location: nil })
      expect(default_file_access.dark?).to be false
    end
  end

  context 'when location-based' do
    let(:access) { { view: 'location-based', download: 'location-based', location: 'spec' } }

    it 'has the object access, including the location' do
      expect(default_file_access.attributes).to eq({ view: 'location-based', download: 'location-based',
                                                     location: 'spec' })
    end
  end

  context 'when dark' do
    let(:access) { { view: 'dark', download: 'none' } }

    it 'is dark' do
      expect(default_file_access.attributes).to eq({ view: 'dark', download: 'none', location: nil })
      expect(default_file_access.dark?).to be true
    end
  end

  context 'when citation-only' do
    let(:access) { { view: 'citation-only', download: 'none' } }

    it 'is dark' do
      expect(default_file_access.attributes).to eq({ view: 'dark', download: 'none', location: nil })
      expect(default_file_access.dark?).to be true
    end
  end

  context 'when embargoed' do
    let(:access) do
      { view: 'dark', download: 'none',
        embargo: { releaseDate: 1.year.from_now.iso8601, view: 'stanford', download: 'stanford' } }
    end

    it 'has the access after the embargo is lifted' do
      expect(default_file_access.attributes).to eq({ view: 'stanford', download: 'stanford', location: nil })
      expect(default_file_access.dark?).to be false
    end
  end
end
