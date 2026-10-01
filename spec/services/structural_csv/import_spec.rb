# frozen_string_literal: true

require 'rails_helper'

RSpec.describe StructuralCsv::Import do
  subject(:result) { described_class.call(rows:, content:) }

  let(:rows) { CSV.parse(csv_string, headers: true).each.with_index(2).map { |row, number| [number, row] } }

  let(:headers) do
    'druid,resource_label,resource_type,sequence,filename,file_label,publish,shelve,preserve,rights_view,' \
      'rights_download,rights_location,mimetype,role,file_language,sdr_generated_text,corrected_for_accessibility'
  end

  let(:content) { create(:content, druid: 'druid:bc123df4567', immutable: false) }

  let(:image1_binary) { create_binary('image1.tif') }
  let(:image2_binary) { create_binary('image2.tif') }
  let(:image3_binary) { create_binary('image3.tif') }

  let!(:first_file_set) do
    create(:content_file_set, content:, position: 1, label: 'Image 1', file_set_type: 'image',
                              external_identifier: 'https://cocina.sul.stanford.edu/fileSet/bc123df4567-1')
  end
  let!(:second_file_set) do
    create(:content_file_set, content:, position: 2, label: 'Image 2', file_set_type: 'image',
                              external_identifier: 'https://cocina.sul.stanford.edu/fileSet/bc123df4567-2')
  end
  let!(:third_file_set) do
    create(:content_file_set, content:, position: 3, label: 'Image 3', file_set_type: 'image',
                              external_identifier: 'https://cocina.sul.stanford.edu/fileSet/bc123df4567-3')
  end

  before do
    create_file(first_file_set, image1_binary, 'https://cocina.sul.stanford.edu/file/bc123df4567-1')
    create_file(second_file_set, image2_binary, 'https://cocina.sul.stanford.edu/file/bc123df4567-2')
    create_file(third_file_set, image3_binary, 'https://cocina.sul.stanford.edu/file/bc123df4567-3')
  end

  def create_binary(filepath)
    create(:content_file_binary, content:, filepath:, file_location: 'deposited', mime_type: 'image/tiff')
  end

  def create_file(content_file_set, content_file_binary, external_identifier)
    create(:content_file, content_file_set:, content_file_binary:, external_identifier:,
                          label: "Label for #{content_file_binary.filepath}", use: 'transcription',
                          language_tag: 'en', sdr_generated_text: true, corrected_for_accessibility: true,
                          width: 100, height: 200)
  end

  def file_sets
    content.content_file_sets.reload
  end

  context 'when the content is immutable' do
    let(:content) { create(:content, immutable: true) }
    let(:csv_string) { headers }

    it 'raises' do
      expect { result }.to raise_error(ArgumentError)
    end
  end

  context 'when reordering, regrouping, and removing file sets and files' do
    # File set 2 moves first, image3 moves into file set 1, file set 3 is removed.
    let(:csv_string) do
      <<~CSV
        #{headers}
        bc123df4567,Second,image,2,image2.tif,Image 2 label,yes,yes,yes,world,world,,image/tiff,,,no,no
        bc123df4567,First,image,1,image1.tif,Image 1 label,yes,yes,yes,world,world,,image/tiff,,,no,no
        bc123df4567,First,image,1,image3.tif,Image 3 label,yes,yes,yes,world,world,,image/tiff,,,no,no
      CSV
    end

    it 'updates the file sets and files' do
      expect(result).to be_success

      expect(file_sets.map(&:external_identifier)).to eq(
        ['https://cocina.sul.stanford.edu/fileSet/bc123df4567-2', 'https://cocina.sul.stanford.edu/fileSet/bc123df4567-1']
      )
      expect(file_sets.map(&:position)).to eq([1, 2])
      expect(file_sets.map(&:label)).to eq(%w[Second First])
      expect(file_sets.last.content_files.map(&:filepath)).to eq(%w[image1.tif image3.tif])
      expect(file_sets.last.content_files.map(&:position)).to eq([1, 2])

      # The moved file keeps its identity and dimensions.
      moved_content_file = file_sets.last.content_files.last
      expect(moved_content_file).to have_attributes(external_identifier: 'https://cocina.sul.stanford.edu/file/bc123df4567-3',
                                                    width: 100, height: 200, label: 'Image 3 label')
      expect(ContentFileSet.exists?(third_file_set.id)).to be false
    end
  end

  context 'when a sequence does not match an existing file set' do
    let(:csv_string) do
      <<~CSV
        #{headers}
        bc123df4567,Image 1,image,1,image1.tif,Image 1 label,yes,yes,yes,world,world,,image/tiff,,,no,no
        bc123df4567,Image 2,image,2,image2.tif,Image 2 label,yes,yes,yes,world,world,,image/tiff,,,no,no
        bc123df4567,New,page,5,image3.tif,Image 3 label,yes,yes,yes,world,world,,image/tiff,,,no,no
      CSV
    end

    it 'creates a new file set' do
      expect(result).to be_success

      expect(file_sets.last).to have_attributes(external_identifier: nil, label: 'New', file_set_type: 'page')
    end
  end

  context 'when a file is omitted' do
    let(:csv_string) do
      <<~CSV
        #{headers}
        bc123df4567,Image 1,image,1,image1.tif,Image 1 label,yes,yes,yes,world,world,,image/tiff,,,no,no
        bc123df4567,Image 2,image,2,image2.tif,Image 2 label,yes,yes,yes,world,world,,image/tiff,,,no,no
      CSV
    end

    it 'removes the file and its binary' do
      expect(result).to be_success

      expect(file_sets.size).to eq(2)
      expect(ContentFileBinary.exists?(image3_binary.id)).to be false
      expect(ContentFileBinary.exists?(image1_binary.id)).to be true
    end
  end

  context 'when optional columns are absent' do
    let(:csv_string) do
      <<~CSV
        druid,sequence,filename,publish,preserve,rights_view,rights_download,rights_location
        bc123df4567,1,image1.tif,yes,no,world,world,
        bc123df4567,2,image2.tif,no,yes,world,world,
        bc123df4567,3,image3.tif,yes,yes,world,world,
      CSV
    end

    it 'uses the existing values' do
      expect(result).to be_success

      expect(file_sets.first).to have_attributes(label: 'Image 1', file_set_type: 'image')
      expect(file_sets.first.content_files.first).to have_attributes(
        label: 'Label for image1.tif', use: 'transcription', language_tag: 'en', sdr_generated_text: true,
        corrected_for_accessibility: true, mime_type: 'image/tiff'
      )
    end

    it 'shelves according to publish' do
      expect(result).to be_success

      expect(file_sets.map { |file_set| file_set.content_files.first.shelve }).to eq([true, false, true])
    end
  end

  context 'when optional columns are present but blank' do
    let(:csv_string) do
      <<~CSV
        #{headers}
        bc123df4567,,image,1,image1.tif,,yes,yes,yes,world,world,,image/tiff,,,,
        bc123df4567,,image,2,image2.tif,,yes,yes,yes,world,world,,image/tiff,,,,
        bc123df4567,,image,3,image3.tif,,yes,yes,yes,world,world,,image/tiff,,,,
      CSV
    end

    it 'uses the blank values' do
      expect(result).to be_success

      expect(file_sets.first.label).to eq('')
      expect(file_sets.first.content_files.first).to have_attributes(
        label: '', use: nil, language_tag: nil, sdr_generated_text: false, corrected_for_accessibility: false
      )
    end
  end

  context 'when values are changed' do
    let(:csv_string) do
      <<~CSV
        #{headers}
        bc123df4567,Image 1,image,1,image1.tif,Image 1 label,no,no,YES,location-based,none,spec,image/jpeg,thumbnail,fr,TRUE,False
        bc123df4567,Image 2,image,2,image2.tif,Image 2 label,yes,yes,yes,world,world,spec,image/tiff,,,no,no
        bc123df4567,Image 3,image,3,image3.tif,Image 3 label,yes,yes,yes,world,world,,image/tiff,,,no,no
      CSV
    end

    it 'updates the files and binaries' do
      expect(result).to be_success

      expect(file_sets.first.content_files.first).to have_attributes(
        publish: false, shelve: false, preserve: true, view: 'location-based', download: 'none', location: 'spec',
        use: 'thumbnail', language_tag: 'fr', sdr_generated_text: true, corrected_for_accessibility: false
      )
      expect(image1_binary.reload.mime_type).to eq('image/jpeg')
    end

    it 'clears the location when access is not location-based' do
      expect(result).to be_success

      expect(file_sets.second.content_files.first.location).to be_nil
    end
  end

  context 'when a file is in multiple file sets' do
    let(:csv_string) do
      <<~CSV
        #{headers}
        bc123df4567,New,image,5,image1.tif,Image 1 label,yes,yes,yes,world,world,,image/tiff,,,no,no
        bc123df4567,Image 1,image,1,image1.tif,Image 1 label,yes,yes,yes,world,world,,image/tiff,,,no,no
        bc123df4567,Image 2,image,2,image2.tif,Image 2 label,yes,yes,yes,world,world,,image/tiff,,,no,no
        bc123df4567,Image 3,image,3,image3.tif,Image 3 label,yes,yes,yes,world,world,,image/tiff,,,no,no
      CSV
    end

    it 'keeps the identity of the file in the same file set' do
      expect(result).to be_success

      expect(file_sets.first.content_files.first.external_identifier).to be_nil
      expect(file_sets.second.content_files.first.external_identifier)
        .to eq('https://cocina.sul.stanford.edu/file/bc123df4567-1')
      expect(file_sets.first.content_files.first.content_file_binary)
        .to eq(file_sets.second.content_files.first.content_file_binary)
    end
  end

  context 'when the rows are invalid' do
    let(:csv_string) do
      <<~CSV
        #{headers}
        bc123df4567,Image 1,image,1,image1.tif,Image 1 label,yes,yes,yes,world,world,,image/tiff,,,no,no
        bc123df4567,Image 2,image,2,image4.tif,Image 2 label,yes,yes,yes,world,world,,image/tiff,,,no,no
      CSV
    end

    it 'returns failure and does not change the content' do
      expect(result).to be_failure
      expect(result.failure).to eq(
        [StructuralCsv::ValidationError.new(3, 'image4.tif is not an existing file (files cannot be added)')]
      )
      expect(file_sets.size).to eq(3)
    end
  end

  context 'when the built records are invalid' do
    let(:csv_string) do
      <<~CSV
        #{headers}
        bc123df4567,Image 1,bogus,1,image1.tif,Image 1 label,yes,yes,yes,world,world,,image/tiff,,,no,no
        bc123df4567,Image 2,image,2,image2.tif,Image 2 label,no,yes,no,world,world,,image/tiff,,,no,no
        bc123df4567,Image 3,image,3,image3.tif,Image 3 label,yes,yes,yes,location-based,none,,image/tiff,,,no,no
      CSV
    end

    it 'returns failure and does not change the content' do
      expect(result).to be_failure
      expect(result.failure).to eq(
        [
          StructuralCsv::ValidationError.new(2, 'File set type is not included in the list'),
          StructuralCsv::ValidationError.new(3, 'image2.tif: Shelve requires publish or preserve'),
          StructuralCsv::ValidationError.new(
            4, 'image3.tif: Access rights are not a valid combination of view, download, and location'
          )
        ]
      )
      expect(file_sets.map(&:file_set_type)).to eq(%w[image image image])
      expect(image1_binary.reload.mime_type).to eq('image/tiff')
    end
  end
end
