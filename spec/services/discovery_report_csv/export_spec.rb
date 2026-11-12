# frozen_string_literal: true

require 'rails_helper'

RSpec.describe DiscoveryReportCsv::Export do
  subject(:csv) { described_class.as_csv(multi_item_deposit_action:) }

  let(:multi_item_deposit_action) { create(:multi_item_deposit_action) }

  before do
    # Created out of manifest order, so that the rows must be ordered by manifest line.
    create(:item_deposit_action, multi_item_deposit_action:, druid: 'druid:fg123hj4589', path: 'folder2',
                                 manifest_line_number: 3, content_type: 'object',
                                 discovery_errors: ['Not an Item', 'Folder not found: folder2'],
                                 discovery_warnings: ['Version cannot be opened'])
    create(:item_deposit_action, multi_item_deposit_action:, druid: 'druid:bc123df4567', path: 'folder1',
                                 manifest_line_number: 2, content_type: 'book')
    create(:item_deposit_action, multi_item_deposit_action:, druid: 'druid:km123mn4512', path: 'folder3',
                                 manifest_line_number: 4, content_type: nil, discovery_errors: ['Object not found'])
    # Another Multi-Item Deposit's Item Deposit.
    create(:item_deposit_action, druid: 'druid:pq123rs4590', discovery_errors: ['Object not found'])
  end

  it 'returns the headers and a row for every Item Deposit, in manifest order' do
    expect(csv).to eq(<<~CSV)
      Manifest line number,Druid,Folder,Content type,Error,Warning
      2,bc123df4567,folder1,book,,
      3,fg123hj4589,folder2,file,Not an Item; Folder not found: folder2,Version cannot be opened
      4,km123mn4512,folder3,,Object not found,
    CSV
  end
end
