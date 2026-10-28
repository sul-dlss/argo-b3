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

  context 'with the agreement content type' do
    let(:content_type) { Cocina::Models::ObjectType.agreement }

    it 'validates agreement resources' do
      expect(result.errors).to include(a_string_ending_with('must be preserved and not published.'))
    end
  end

  context 'with the geo content type' do
    let(:content_type) { Cocina::Models::ObjectType.geo }

    it 'validates object resources' do
      expect(result.errors).to eq(['There are no object resources.'])
    end
  end

  context 'with the 3d content type' do
    let(:content_type) { Cocina::Models::ObjectType.three_dimensional }

    it 'validates 3d resources' do
      expect(result).to have_attributes(
        errors: [], warnings: ['There is not exactly one 3D resource containing exactly one GLB file.']
      )
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

  context 'with the media content type' do
    let(:content_type) { Cocina::Models::ObjectType.media }

    it 'provides a warning instead of an error' do
      expect(result).to have_attributes(
        errors: [],
        warnings: [
          'No video or audio resource has exactly one MP4 (video) or M4A (audio) file, ' \
          'or an MP3, MOV, MKV, or WAV file.'
        ]
      )
    end
  end

  context 'with the webarchive-seed content type' do
    let(:content_type) { Cocina::Models::ObjectType.webarchive_seed }

    it 'validates published files' do
      expect(result.errors).to eq(['Resource 1 (File 1) has published files that are not JP2: image1.tif.'])
    end
  end

  context 'when there are hierarchical filepaths' do
    let(:hierarchy_error) { a_string_starting_with('Hierarchical filepaths') }

    before do
      content_file_binary = create(:content_file_binary, content:, filepath: 'folder1/data.zip')
      create(:content_file, content_file_set: content.content_file_sets.first, content_file_binary:)
    end

    context 'with the book content type' do
      it 'has an error' do
        expect(result.errors).to include(hierarchy_error)
      end
    end

    context 'with the webarchive-binary content type' do
      let(:content_type) { Cocina::Models::ObjectType.webarchive_binary }

      it 'has an error' do
        expect(result.errors).to include(hierarchy_error)
      end
    end

    context 'with a content type without a validator' do
      let(:content_type) { Cocina::Models::ObjectType.manuscript }

      it 'has an error' do
        expect(result.errors).to contain_exactly(hierarchy_error)
      end
    end

    context 'with the object content type' do
      let(:content_type) { Cocina::Models::ObjectType.object }

      it 'has no error' do
        expect(result.errors).not_to include(hierarchy_error)
      end
    end

    context 'with the geo content type' do
      let(:content_type) { Cocina::Models::ObjectType.geo }

      it 'has no error' do
        expect(result.errors).not_to include(hierarchy_error)
      end
    end

    context 'when dark' do
      let(:access) { { view: 'dark', download: 'none' } }

      it 'has an error' do
        expect(result.errors).to contain_exactly(hierarchy_error)
      end
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
