# frozen_string_literal: true

require 'rails_helper'

RSpec.describe StructureReportCsv::Export do
  subject(:csv) { described_class.as_csv(multi_item_deposit_action:) }

  let(:multi_item_deposit_action) { create(:multi_item_deposit_action) }

  context 'when Item Deposits have a mix of errors, warnings, and neither' do
    before do
      content = create(:content, druid: 'druid:bc123df4567')
      create(:content_file_binary, content:, filepath: 'image1.tif')
      create(:content_file_binary, content:, filepath: 'image2.tif')
      create(:item_deposit_action, multi_item_deposit_action:, druid: 'druid:bc123df4567', path: 'folder1',
                                   manifest_line_number: 2, content:, content_type: 'image', initial_version: true)
      create(:item_deposit_action, multi_item_deposit_action:, druid: 'druid:cd234fg5678', path: 'folder2',
                                   manifest_line_number: 3, content_type: 'image', initial_version: false,
                                   content_type_structure_warnings: ['No displayable image'])
      create(:item_deposit_action, multi_item_deposit_action:, druid: 'druid:df345gh6789', path: 'folder3',
                                   manifest_line_number: 4, content_type: 'object', initial_version: false,
                                   structural_csv_errors: ['Row 2: Missing filename'],
                                   content_type_structure_errors: ['Page has more than one image'],
                                   content_type_structure_warnings: ['No displayable image'])
      create(:item_deposit_action, multi_item_deposit_action:, druid: 'druid:fg456hj7890', path: 'folder4',
                                   manifest_line_number: 5, content_type: nil, initial_version: true,
                                   structural_csv_errors: ['Row 3: Missing filename'])
      # Another Multi-Item Deposit's Item Deposit.
      create(:item_deposit_action, druid: 'druid:gh567jk8901', structural_csv_errors: ['Row 2: Missing filename'])
    end

    it 'returns the headers and a row per error, then per warning, then per OK Item Deposit' do
      expect(csv).to eq(<<~CSV)
        Druid,Folder,Number of files,Content type,Deposit type,Status,Message
        df345gh6789,folder3,0,file,redeposit,error,Row 2: Missing filename
        df345gh6789,folder3,0,file,redeposit,error,Page has more than one image
        fg456hj7890,folder4,0,,new item,error,Row 3: Missing filename
        df345gh6789,folder3,0,file,redeposit,warning,No displayable image
        cd234fg5678,folder2,0,image,redeposit,warning,No displayable image
        bc123df4567,folder1,2,image,new item,OK,
      CSV
    end
  end
end
