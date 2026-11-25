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

  context 'when access values are not allowed' do
    let(:csv_string) do
      <<~CSV
        #{headers}
        bc123df4567,Image 1,image,1,image1.tif,,yes,yes,no,stanfrod,world,,image/tiff,,,,
        bc123df4567,Image 2,image,2,image2.tif,,yes,yes,no,world,everyone,,image/tiff,,,,
        bc123df4567,Image 3,image,3,image1.tif,,yes,yes,no,citation-only,none,,image/tiff,,,,
        bc123df4567,Image 4,image,4,image2.tif,,yes,yes,no,location-based,none,moon,image/tiff,,,,
      CSV
    end

    it 'returns an error naming the column and value, and not an invalid combination error' do
      expect(reasons).to eq(
        [
          [2, 'Value for "rights_view" ("stanfrod") is not a valid view access'],
          [3, 'Value for "rights_download" ("everyone") is not a valid download access'],
          [4, 'Value for "rights_view" ("citation-only") is not a valid view access'],
          [5, 'Value for "rights_location" ("moon") is not a valid location']
        ]
      )
    end
  end

  context 'when access values are not a valid combination' do
    let(:csv_string) do
      <<~CSV
        #{headers}
        bc123df4567,Image 1,image,1,image1.tif,,yes,yes,no,stanford,world,,image/tiff,,,,
        bc123df4567,Image 2,image,2,image2.tif,,yes,yes,no,location-based,none,,image/tiff,,,,
        bc123df4567,Image 3,image,3,image1.tif,,yes,yes,no,dark,world,spec,image/tiff,,,,
      CSV
    end

    it 'returns an error naming the values' do
      expect(reasons).to eq(
        [
          [2, 'Access rights (view "stanford", download "world", location blank) are not a valid combination'],
          [3, 'Access rights (view "location-based", download "none", location blank) are not a valid combination'],
          [4, 'Access rights (view "dark", download "world", location "spec") are not a valid combination']
        ]
      )
    end
  end

  context 'when a location is given for access that is not location-based' do
    let(:csv_string) do
      <<~CSV
        #{headers}
        bc123df4567,Image 1,image,1,image1.tif,,yes,yes,no,world,world,spec,image/tiff,,,,
      CSV
    end

    it 'returns no errors, since the location is not used' do
      expect(errors).to be_empty
    end
  end

  context 'when an access value is missing' do
    let(:csv_string) do
      <<~CSV
        #{headers}
        bc123df4567,Image 1,image,1,image1.tif,,yes,yes,no,,world,,image/tiff,,,,
      CSV
    end

    it 'returns only the missing value error' do
      expect(reasons).to eq([[2, 'Value for "rights_view" is missing']])
    end
  end

  context 'when a file is shelved without being published or preserved' do
    let(:csv_string) do
      <<~CSV
        #{headers}
        bc123df4567,Image 1,image,1,image1.tif,,no,yes,no,world,world,,image/tiff,,,,
        bc123df4567,Image 2,image,2,image2.tif,,maybe,yes,no,world,world,,image/tiff,,,,
      CSV
    end

    it 'returns an error, except when publish or preserve is not a boolean' do
      expect(reasons).to eq(
        [
          [2, 'Value for "shelve" ("yes") requires publish or preserve'],
          [3, 'Value for "publish" ("maybe") must be yes, no, true, or false']
        ]
      )
    end
  end

  context 'when a resource type is not allowed' do
    let(:csv_string) do
      <<~CSV
        #{headers}
        bc123df4567,Image 1,bogus,1,image1.tif,,yes,yes,no,world,world,,image/tiff,,,,
      CSV
    end

    it 'returns an error' do
      expect(reasons).to eq([[2, 'Value for "resource_type" ("bogus") is not a valid resource type']])
    end
  end

  context 'when a resource type in a group is missing or not allowed' do
    let(:csv_string) do
      <<~CSV
        #{headers}
        bc123df4567,Image 1,bogus,1,image1.tif,,yes,yes,no,world,world,,image/tiff,,,,
        bc123df4567,Image 1,image,1,image2.tif,,yes,yes,no,world,world,,image/tiff,,,,
        bc123df4567,Image 1,,1,image1.tif,,yes,yes,no,world,world,,image/tiff,,,,
        bc123df4567,Image 1,page,1,image2.tif,,yes,yes,no,world,world,,image/tiff,,,,
      CSV
    end

    it 'reports it once, and compares only the allowed resource types' do
      expect(reasons).to eq(
        [
          [2, 'Value for "resource_type" ("bogus") is not a valid resource type'],
          [4, 'Value for "resource_type" is missing'],
          [4, 'image1.tif appears more than once for sequence 1'],
          [5, 'Value for "resource_type" must be the same for every row with sequence 1'],
          [5, 'image2.tif appears more than once for sequence 1']
        ]
      )
    end
  end

  context 'when there are problems in several rows and of several kinds' do
    subject(:errors) { described_class.call(rows:, content_file_binaries_by_filepath:, allow_file_deletion: false) }

    let(:csv_string) do
      <<~CSV
        #{headers}
        bc123df4567,Image 1,image,1,image1.tif,,yes,yes,maybe,world,world,,image/tiff,,,,
        bc123df4567,Image 2,image,2,image1.tif,,yes,yes,no,world,world,,image/jpeg,,,,
        bc123df4567,Image 1,image,1,image1.tif,,yes,yes,no,stanfrod,world,,image/tiff,,,,
      CSV
    end

    it 'returns every error, by row number, with errors that are not for a row last' do
      expect(reasons).to eq(
        [
          [2, 'Value for "preserve" ("maybe") must be yes, no, true, or false'],
          [3, 'image1.tif has different mimetypes ("image/tiff" and "image/jpeg")'],
          [4, 'Value for "rights_view" ("stanfrod") is not a valid view access'],
          [4, 'Rows for sequence 1 must be together'],
          [nil, 'Files would be deleted: image2.tif. Select "Allow files to be deleted" to delete them.']
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

    it 'returns no errors' do
      expect(reasons).to be_empty
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

  context 'when files would be deleted and deletion is not allowed' do
    subject(:errors) { described_class.call(rows:, content_file_binaries_by_filepath:, allow_file_deletion: false) }

    let(:csv_string) do
      <<~CSV
        #{headers}
        bc123df4567,Image 1,image,1,image1.tif,,yes,yes,no,world,world,,image/tiff,,,,
        bc123df4567,Image 2,image,bogus,image1.tif,,yes,yes,no,world,world,,image/tiff,,,,
      CSV
    end

    it 'returns the deletion error, not for a row, with the row errors' do
      expect(reasons).to eq(
        [
          [3, 'Sequence "bogus" is not a positive integer'],
          [nil, 'Files would be deleted: image2.tif. Select "Allow files to be deleted" to delete them.']
        ]
      )
    end
  end

  context 'when files would be deleted and deletion is allowed' do
    let(:csv_string) do
      <<~CSV
        #{headers}
        bc123df4567,Image 1,image,1,image1.tif,,yes,yes,no,world,world,,image/tiff,,,,
      CSV
    end

    it 'returns no errors' do
      expect(errors).to be_empty
    end
  end

  context 'when files are moved between file sets and deletion is not allowed' do
    subject(:errors) { described_class.call(rows:, content_file_binaries_by_filepath:, allow_file_deletion: false) }

    let(:csv_string) do
      <<~CSV
        #{headers}
        bc123df4567,Image 1,image,1,image2.tif,,yes,yes,no,world,world,,image/tiff,,,,
        bc123df4567,Image 2,image,2,image1.tif,,yes,yes,no,world,world,,image/tiff,,,,
      CSV
    end

    it 'returns no errors' do
      expect(errors).to be_empty
    end
  end
end
