# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ContentFileSet do
  describe 'file_set_type validation' do
    it 'is valid with a Cocina file set type' do
      expect(build(:content_file_set, file_set_type: 'image')).to be_valid
    end

    it 'is invalid with a file set type that is not a Cocina file set type' do
      content_file_set = build(:content_file_set, file_set_type: 'bogus')

      expect(content_file_set).not_to be_valid
      expect(content_file_set.errors[:file_set_type]).to include('is not included in the list')
    end
  end

  describe 'deposit validation context' do
    it 'is valid with an external_identifier' do
      expect(build(:content_file_set, external_identifier: 'https://cocina.sul.stanford.edu/fileSet/abc')).to(
        be_valid(:deposit)
      )
    end

    it 'is invalid without an external_identifier' do
      content_file_set = build(:content_file_set, external_identifier: nil)
      expect(content_file_set).not_to be_valid(:deposit)
      expect(content_file_set.errors[:external_identifier]).to include("can't be blank")
    end
  end

  describe '#move' do
    let(:content) { create(:content) }
    let!(:first_content_file_set) { create(:content_file_set, content:, position: 1, label: 'First') }
    let!(:second_content_file_set) { create(:content_file_set, content:, position: 2, label: 'Second') }

    it 'moves the file set up' do
      second_content_file_set.move('up')

      expect(content.content_file_sets.pluck(:label)).to eq(%w[Second First])
    end

    it 'moves the file set down' do
      first_content_file_set.move('down')

      expect(content.content_file_sets.pluck(:label)).to eq(%w[Second First])
    end

    it 'does not move the first file set up or the last file set down' do
      first_content_file_set.move('up')
      second_content_file_set.move('down')

      expect(content.content_file_sets.pluck(:label, :position)).to eq([['First', 1], ['Second', 2]])
    end

    it 'raises for an unknown direction' do
      expect { first_content_file_set.move('sideways') }.to raise_error(KeyError)
    end
  end
end
