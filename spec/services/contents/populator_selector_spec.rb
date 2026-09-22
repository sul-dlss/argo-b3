# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Contents::PopulatorSelector do
  subject(:result) { described_class.call(content:, cocina_object:) }

  let(:content) { create(:content, druid: 'druid:bc123df4567') }
  let(:cocina_object) do
    instance_double(Cocina::Models::DROWithMetadata, type: cocina_type, access: cocina_access)
  end
  let(:cocina_type) { Cocina::Models::ObjectType.image }
  let(:cocina_access) { instance_double(Cocina::Models::DROAccess, view: 'world') }

  before do
    create(:content_file_binary, content:, filepath: 'image_0001.tif', mime_type: 'image/tiff')
  end

  context 'when the content type has no populator of its own' do
    it 'selects the fallback populator without reasons' do
      expect(result).to have_attributes(populator_for_content_type: Contents::Populators::FileSetPerFile,
                                        actual_populator: Contents::Populators::FileSetPerFile,
                                        reasons: [])
    end
  end

  context 'when the populator for the content type cannot be used' do
    let(:populator_class) do
      Class.new(Contents::Populators::Base) do
        def self.disqualifying_reasons(**)
          [:dark]
        end
      end
    end

    before do
      stub_const('Contents::PopulatorSelector::POPULATORS_FOR_CONTENT_TYPES', { cocina_type => populator_class })
    end

    it 'falls back to the file set per file populator' do
      expect(result).to have_attributes(populator_for_content_type: populator_class,
                                        actual_populator: Contents::Populators::FileSetPerFile,
                                        reasons: [:dark])
    end
  end

  context 'when a binary does not have a mime type' do
    let(:content_file_binary) { create(:content_file_binary, content:, filepath: 'image_0002.tif', mime_type: nil) }

    before do
      allow(Contents::Analyzer).to receive(:call)
      content_file_binary
    end

    it 'populates the mime type before selecting' do
      result
      expect(Contents::Analyzer).to have_received(:call).with(content_file_binary:, mime_type_only: true)
    end
  end
end
