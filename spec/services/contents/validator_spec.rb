# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Contents::Validator do
  subject(:result) { described_class.call(content:, cocina_object:, content_type:) }

  let(:content) { create(:content, druid: 'druid:bc123df4567') }
  let(:cocina_object) do
    build(:dro_with_metadata, id: 'druid:bc123df4567', type: Cocina::Models::ObjectType.book).new(access:)
  end
  let(:access) { { view: 'world', download: 'world' } }
  let(:content_type) { nil }
  let(:error) { 'Resource 1 (File 1) has published files but is not a page or object resource.' }

  before do
    # Published files in a file resource are an error for a book.
    content_file_set = create(:content_file_set, content:, file_set_type: 'file', label: 'File 1')
    create(:content_file, content_file_set:, publish: true)
  end

  context 'without a content type' do
    it 'validates for the content type of the cocina object' do
      expect(result.errors).to eq([error])
    end
  end

  context 'with a content type' do
    let(:content_type) { Cocina::Models::ObjectType.object }

    it 'validates for the content type' do
      expect(result).to have_attributes(errors: [], warnings: [])
    end
  end

  context 'with the webarchive-binary content type' do
    let(:content_type) { Cocina::Models::ObjectType.webarchive_binary }

    before do
      content_file_binary = create(:content_file_binary, content:, filepath: 'data.zip')
      create(:content_file, content_file_set: content.content_file_sets.first, content_file_binary:, publish: true)
    end

    it 'validates file resources' do
      expect(result.errors).to eq(['Resource 1 (File 1) has more than one published file.'])
    end
  end

  context 'with the document content type' do
    let(:content_type) { Cocina::Models::ObjectType.document }

    it 'validates document resources' do
      expect(result).to have_attributes(errors: [], warnings: ['No document resource has exactly one PDF file.'])
    end
  end

  context 'with the image content type' do
    let(:content_type) { Cocina::Models::ObjectType.image }

    it 'validates image resources' do
      expect(result.errors).to eq(['Resource 1 (File 1) has published files but is not an image or object resource.'])
    end
  end

  context 'with the map content type' do
    let(:content_type) { Cocina::Models::ObjectType.map }

    it 'validates image resources' do
      expect(result.errors).to eq(['Resource 1 (File 1) has published files but is not an image or object resource.'])
    end
  end

  context 'with a content type without a validator of its own' do
    let(:content_type) { Cocina::Models::ObjectType.media }

    it 'validates nothing' do
      expect(result).to have_attributes(errors: [], warnings: [])
    end
  end

  context 'when dark' do
    let(:access) { { view: 'dark', download: 'none' } }

    it 'has warnings instead of errors' do
      expect(result).to have_attributes(errors: [], warnings: include(error))
    end
  end

  context 'when citation-only' do
    let(:access) { { view: 'citation-only', download: 'none' } }

    it 'has warnings instead of errors' do
      expect(result).to have_attributes(errors: [], warnings: include(error))
    end
  end

  context 'when embargoed as dark' do
    let(:access) do
      { view: 'world', download: 'world',
        embargo: { releaseDate: 1.year.from_now.iso8601, view: 'dark', download: 'none' } }
    end

    it 'has warnings instead of errors' do
      expect(result).to have_attributes(errors: [], warnings: include(error))
    end
  end
end
