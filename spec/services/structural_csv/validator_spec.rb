# frozen_string_literal: true

require 'rails_helper'

RSpec.describe StructuralCsv::Validator do
  subject(:errors) { described_class.call(rows:, content_file_binaries_by_filepath:) }

  let(:rows) do
    CSV.parse(csv_string, headers: true).each.with_index(2).map do |csv_row, number|
      StructuralCsv::Row.new(number:, csv_row:)
    end
  end

  let(:headers) do
    'druid,resource_label,resource_type,sequence,filename,file_label,publish,shelve,preserve,rights_view,' \
      'rights_download,rights_location,mimetype,role,file_language,sdr_generated_text,corrected_for_accessibility'
  end

  let(:content) { create(:content) }
  let(:content_file_binaries_by_filepath) do
    content.content_file_binaries.includes(:content_files).index_by(&:filepath)
  end

  before do
    %w[image1.tif image2.tif].each do |filepath|
      content_file_binary = create(:content_file_binary, content:, filepath:, file_location: 'deposited')
      create(:content_file, content_file_binary:, content_file_set: create(:content_file_set, content:),
                            preserve: false, publish: true)
    end
  end

  def reasons
    errors.map { |error| [error.line_number, error.reason] }
  end

  context 'when the rows are valid' do
    let(:csv_string) do
      <<~CSV
        #{headers}
        bc123df4567,Image 1,image,1,image1.tif,,yes,yes,no,world,world,,image/tiff,,,,
        bc123df4567,Image 1,image,1,image2.tif,,yes,yes,no,world,world,,image/tiff,,,,
        bc123df4567,Image 2,image,2,image1.tif,,yes,yes,no,world,world,,image/tiff,,,,

      CSV
    end

    it 'returns no errors' do
      expect(errors).to be_empty
    end
  end

  context 'when required columns are missing' do
    let(:csv_string) do
      <<~CSV
        druid,sequence,filename,publish,rights_view,rights_download
        bc123df4567,bogus,image1.tif,yes,world,world
      CSV
    end

    it 'returns only the column errors' do
      expect(reasons).to eq(
        [[1, 'Missing required column "preserve"'], [1, 'Missing required column "rights_location"']]
      )
    end
  end

  context 'when there are no rows' do
    let(:csv_string) do
      <<~CSV
        #{headers}
        bc123df4567,,,,,,,,,,,,,,,,
      CSV
    end

    it 'returns an error' do
      expect(reasons).to eq([[2, 'No files to import']])
    end
  end

  context 'when a row has invalid values' do
    let(:csv_string) do
      <<~CSV
        #{headers}
        bc123df4567,Image 1,,0,,,maybe,,Y,,,,,,,maybe,
      CSV
    end

    it 'returns an error for each value' do
      expect(reasons).to eq(
        [
          [2, 'Sequence "0" is not a positive integer'],
          [2, 'Value for "filename" is missing'],
          [2, 'Value for "rights_view" is missing'],
          [2, 'Value for "rights_download" is missing'],
          [2, 'Value for "resource_type" is missing'],
          [2, 'Value for "mimetype" is missing'],
          [2, 'Value for "publish" ("maybe") must be yes, no, true, or false'],
          [2, 'Value for "preserve" ("Y") must be yes, no, true, or false'],
          [2, 'Value for "shelve" ("") must be yes, no, true, or false'],
          [2, 'Value for "sdr_generated_text" ("maybe") must be yes, no, true, or false']
        ]
      )
    end
  end

  context 'when a file is new' do
    let(:csv_string) do
      <<~CSV
        #{headers}
        bc123df4567,Image 1,image,1,image3.tif,,yes,yes,no,world,world,,image/tiff,,,,
      CSV
    end

    it 'returns an error' do
      expect(reasons).to eq([[2, 'image3.tif is not an existing file (files cannot be added)']])
    end
  end

  context 'when a deposited file changes from preserve=no to preserve=yes' do
    let(:csv_string) do
      <<~CSV
        #{headers}
        bc123df4567,Image 1,image,1,image1.tif,,yes,yes,yes,world,world,,image/tiff,,,,
      CSV
    end

    it 'returns an error' do
      expect(reasons).to eq([[2, 'image1.tif cannot be changed from preserve=no to preserve=yes']])
    end
  end

  context 'when a file has different mimetypes' do
    let(:csv_string) do
      <<~CSV
        #{headers}
        bc123df4567,Image 1,image,1,image1.tif,,yes,yes,no,world,world,,image/tiff,,,,
        bc123df4567,Image 2,image,2,image1.tif,,yes,yes,no,world,world,,image/jpeg,,,,
      CSV
    end

    it 'returns an error' do
      expect(reasons).to eq([[3, 'image1.tif has different mimetypes ("image/tiff" and "image/jpeg")']])
    end
  end

  context 'when the rows for a sequence are not together' do
    let(:csv_string) do
      <<~CSV
        #{headers}
        bc123df4567,Image 1,image,1,image1.tif,,yes,yes,no,world,world,,image/tiff,,,,
        bc123df4567,Image 2,image,2,image2.tif,,yes,yes,no,world,world,,image/tiff,,,,
        bc123df4567,Image 1,image,1,image2.tif,,yes,yes,no,world,world,,image/tiff,,,,
      CSV
    end

    it 'returns an error' do
      expect(reasons).to eq([[4, 'Rows for sequence 1 must be together']])
    end
  end

  context 'when the rows for a sequence have different file set values or repeat a file' do
    let(:csv_string) do
      <<~CSV
        #{headers}
        bc123df4567,Image 1,image,1,image1.tif,,yes,yes,no,world,world,,image/tiff,,,,
        bc123df4567,Image 2,page,1,image1.tif,,yes,yes,no,world,world,,image/tiff,,,,
      CSV
    end

    it 'returns errors' do
      expect(reasons).to eq(
        [
          [3, 'Value for "resource_label" must be the same for every row with sequence 1'],
          [3, 'Value for "resource_type" must be the same for every row with sequence 1'],
          [3, 'image1.tif appears more than once for sequence 1']
        ]
      )
    end
  end
end
