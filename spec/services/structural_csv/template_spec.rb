# frozen_string_literal: true

require 'rails_helper'

RSpec.describe StructuralCsv::Template do
  subject(:csv) { described_class.as_csv(multi_item_deposit_action:) }

  let(:multi_item_deposit_action) { create(:multi_item_deposit_action) }
  let(:first_content) { create(:content, :mutable, druid: 'druid:bc123df4567') }
  let(:second_content) { create(:content, :mutable, druid: 'druid:fg123hj4589') }

  let(:cocina_objects) do
    {
      'druid:bc123df4567' => build(:dro, id: 'druid:bc123df4567').new(access: { view: 'citation-only',
                                                                                download: 'none' }),
      'druid:fg123hj4589' => build(:dro, id: 'druid:fg123hj4589').new(
        access: { view: 'world', download: 'location-based', location: 'spec' }
      )
    }
  end

  before do
    allow(Sdr::Repository).to receive(:find_all).and_return(cocina_objects)
    create(:item_deposit_action, multi_item_deposit_action:, druid: 'druid:fg123hj4589', manifest_line_number: 3,
                                 content: second_content)
    create(:item_deposit_action, multi_item_deposit_action:, druid: 'druid:bc123df4567', manifest_line_number: 2,
                                 content: first_content)
    create(:item_deposit_action, multi_item_deposit_action:, druid: 'druid:km123mn4512', manifest_line_number: 4)
    create(:content_file_binary, content: first_content, filepath: 'image2.tif', mime_type: 'image/tiff')
    create(:content_file_binary, content: first_content, filepath: 'image1.tif', mime_type: 'image/tiff')
    create(:content_file_binary, content: second_content, filepath: 'folder1/document.pdf',
                                 mime_type: 'application/pdf')
  end

  it 'returns the headers and a row for each file of each Item Deposit with a Content, with its Object Access' do
    expect(csv).to eq(<<~CSV)
      druid,resource_label,resource_type,sequence,filename,file_label,publish,shelve,preserve,rights_view,rights_download,rights_location,mimetype,role,file_language,sdr_generated_text,corrected_for_accessibility
      bc123df4567,,,,image1.tif,,,,,dark,none,,image/tiff,,,,
      bc123df4567,,,,image2.tif,,,,,dark,none,,image/tiff,,,,
      fg123hj4589,,,,folder1/document.pdf,,,,,world,location-based,spec,application/pdf,,,,
    CSV
  end

  it 'gets the objects from DSA in one batch' do
    csv

    expect(Sdr::Repository).to have_received(:find_all)
      .once.with(druids: contain_exactly('druid:bc123df4567', 'druid:fg123hj4589'))
  end

  context 'when the access is not location-based and an object is not found' do
    let(:cocina_objects) do
      {
        'druid:bc123df4567' => build(:dro, id: 'druid:bc123df4567').new(access: { view: 'world', download: 'world' })
      }
    end

    it 'leaves rights_location blank and the rights of an object not found blank' do
      expect(csv.lines.drop(1)).to eq(
        ["bc123df4567,,,,image1.tif,,,,,world,world,,image/tiff,,,,\n",
         "bc123df4567,,,,image2.tif,,,,,world,world,,image/tiff,,,,\n",
         "fg123hj4589,,,,folder1/document.pdf,,,,,,,,application/pdf,,,,\n"]
      )
    end
  end
end
