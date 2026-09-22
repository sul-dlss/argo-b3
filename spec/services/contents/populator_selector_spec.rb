# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Contents::PopulatorSelector do
  subject(:result) { described_class.call(content:, cocina_object:) }

  let(:content) { create(:content, druid: 'druid:bc123df4567') }
  let(:cocina_object) do
    instance_double(Cocina::Models::DROWithMetadata, type: cocina_type, access: cocina_access)
  end
  let(:cocina_type) { Cocina::Models::ObjectType.book }
  let(:cocina_access) { instance_double(Cocina::Models::DROAccess, view: 'world') }

  before do
    create(:content_file_binary, content:, filepath: 'page_0001.tif', mime_type: 'image/tiff')
  end

  context 'when the content type has no populator of its own' do
    let(:cocina_type) { Cocina::Models::ObjectType.image }

    it 'selects the fallback populator without reasons' do
      expect(result).to have_attributes(populator_for_content_type: Contents::Populators::FileSetPerFile,
                                        actual_populator: Contents::Populators::FileSetPerFile,
                                        reasons: [])
    end
  end

  context 'when the content type is book and the book populator can be used' do
    it 'selects the book populator without reasons' do
      expect(result).to have_attributes(populator_for_content_type: Contents::Populators::Book,
                                        actual_populator: Contents::Populators::Book,
                                        reasons: [])
    end
  end

  context 'when the object is dark' do
    let(:cocina_access) { instance_double(Cocina::Models::DROAccess, view: 'dark') }

    it 'falls back to the file set per file populator' do
      expect(result).to have_attributes(populator_for_content_type: Contents::Populators::Book,
                                        actual_populator: Contents::Populators::FileSetPerFile,
                                        reasons: [:dark])
    end
  end

  context 'when the files are organized into folders' do
    before do
      create(:content_file_binary, content:, filepath: 'folder/page_0002.tif', mime_type: 'image/tiff')
    end

    it 'falls back to the file set per file populator' do
      expect(result).to have_attributes(actual_populator: Contents::Populators::FileSetPerFile,
                                        reasons: [:hierarchical_files])
    end
  end

  context 'when there are no images' do
    let(:content) { create(:content, druid: 'druid:bd456fg7890') }

    before do
      content.content_file_binaries.destroy_all
      create(:content_file_binary, content:, filepath: 'notes.pdf', mime_type: 'application/pdf')
    end

    it 'falls back to the file set per file populator' do
      expect(result).to have_attributes(actual_populator: Contents::Populators::FileSetPerFile,
                                        reasons: [:no_images])
    end
  end

  context 'when more than one reason applies' do
    let(:cocina_access) { instance_double(Cocina::Models::DROAccess, view: 'dark') }

    before do
      content.content_file_binaries.destroy_all
      create(:content_file_binary, content:, filepath: 'folder/notes.pdf', mime_type: 'application/pdf')
    end

    it 'provides all of the reasons in order' do
      expect(result).to have_attributes(actual_populator: Contents::Populators::FileSetPerFile,
                                        reasons: %i[dark hierarchical_files no_images])
    end
  end

  context 'when a binary does not have a mime type' do
    let(:content_file_binary) { create(:content_file_binary, content:, filepath: 'page_0002.tif', mime_type: nil) }

    before do
      allow(Contents::Analyzer).to receive(:call) do |content_file_binary:, **|
        content_file_binary.update!(mime_type: 'image/tiff')
      end
      content_file_binary
    end

    it 'populates the mime type before selecting' do
      expect(result.actual_populator).to eq(Contents::Populators::Book)
      expect(Contents::Analyzer).to have_received(:call).with(content_file_binary:, mime_type_only: true)
    end
  end
end
