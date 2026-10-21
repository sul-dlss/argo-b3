# frozen_string_literal: true

require 'rails_helper'

RSpec.describe StructuralCsv::Template do
  subject(:csv) { described_class.as_csv(multi_item_deposit_action:) }

  let(:multi_item_deposit_action) { create(:multi_item_deposit_action) }
  let(:first_content) { create(:content, :mutable, druid: 'druid:bc123df4567') }
  let(:second_content) { create(:content, :mutable, druid: 'druid:fg123hj4589') }

  before do
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

  it 'returns the headers and a row for each file of each Item Deposit with a Content' do
    expect(csv).to eq(<<~CSV)
      druid,resource_label,resource_type,sequence,filename,file_label,publish,shelve,preserve,rights_view,rights_download,rights_location,mimetype,role,file_language,sdr_generated_text,corrected_for_accessibility
      bc123df4567,,,,image1.tif,,,,,,,,image/tiff,,,,
      bc123df4567,,,,image2.tif,,,,,,,,image/tiff,,,,
      fg123hj4589,,,,folder1/document.pdf,,,,,,,,application/pdf,,,,
    CSV
  end
end
