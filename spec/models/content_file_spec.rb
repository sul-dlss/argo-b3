# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ContentFile do
  describe 'shelve validation' do
    it 'is valid when shelved and published but not preserved' do
      expect(build(:content_file, shelve: true, publish: true, preserve: false)).to be_valid
    end

    it 'is valid when shelved and preserved but not published' do
      expect(build(:content_file, shelve: true, publish: false, preserve: true)).to be_valid
    end

    it 'is valid when not shelved, published, or preserved' do
      expect(build(:content_file, shelve: false, publish: false, preserve: false)).to be_valid
    end

    it 'is invalid when shelved but neither published nor preserved' do
      content_file = build(:content_file, shelve: true, publish: false, preserve: false)

      expect(content_file).not_to be_valid
      expect(content_file.errors[:shelve]).to include('requires publish or preserve')
    end
  end

  describe 'access validation' do
    it 'is valid with location-based access and a location' do
      expect(build(:content_file, view: 'location-based', download: 'location-based', location: 'spec')).to be_valid
    end

    it 'is invalid with location-based access but no location' do
      content_file = build(:content_file, view: 'location-based', download: 'location-based', location: nil)

      expect(content_file).not_to be_valid
      expect(content_file.errors[:base])
        .to include('Access rights are not a valid combination of view, download, and location')
    end

    it 'is invalid with a location when access is not location-based' do
      expect(build(:content_file, view: 'world', download: 'world', location: 'spec')).not_to be_valid
    end

    it 'is invalid with citation-only access' do
      expect(build(:content_file, view: 'citation-only', download: 'none')).not_to be_valid
    end
  end

  describe 'deposit validation context' do
    let(:deposit_ready_attributes) do
      {
        external_identifier: 'https://cocina.sul.stanford.edu/file/abc'
      }
    end

    it 'is valid when required attributes are present' do
      expect(build(:content_file, **deposit_ready_attributes)).to be_valid(:deposit)
    end

    it 'is invalid without external_identifier' do
      content_file = build(:content_file, **deposit_ready_attributes, external_identifier: nil)

      expect(content_file).not_to be_valid(:deposit)
      expect(content_file.errors[:external_identifier]).to include("can't be blank")
    end
  end
end
