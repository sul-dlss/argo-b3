# frozen_string_literal: true

require 'rails_helper'

RSpec.describe AccessRightsSupport do
  describe '.valid?' do
    [
      { view: 'dark', download: 'none', location: nil },
      { view: 'citation-only', download: 'none', location: nil },
      { view: 'location-based', download: 'location-based', location: 'spec' },
      { view: 'location-based', download: 'none', location: 'music' },
      { view: 'stanford', download: 'location-based', location: 'spec' },
      { view: 'world', download: 'location-based', location: 'spec' },
      { view: 'stanford', download: 'stanford', location: nil },
      { view: 'world', download: 'world', location: nil },
      { view: 'world', download: 'stanford', location: nil },
      { view: 'world', download: 'none', location: nil }
    ].each do |access_rights|
      it "is true for #{access_rights}" do
        expect(described_class.valid?(**access_rights)).to be true
      end
    end

    [
      { view: 'dark', download: 'world', location: nil },
      { view: 'stanford', download: 'world', location: nil },
      { view: 'location-based', download: 'none', location: nil },
      { view: 'location-based', download: 'none', location: 'unknown' },
      { view: 'world', download: 'world', location: 'spec' },
      { view: 'citation-only', download: 'world', location: nil }
    ].each do |access_rights|
      it "is false for #{access_rights}" do
        expect(described_class.valid?(**access_rights)).to be false
      end
    end

    it 'is false for citation-only when citation-only is not allowed' do
      expect(described_class.valid?(view: 'citation-only', download: 'none', location: nil, citation_only: false))
        .to be false
    end
  end
end
