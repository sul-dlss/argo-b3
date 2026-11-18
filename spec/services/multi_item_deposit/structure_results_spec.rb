# frozen_string_literal: true

require 'rails_helper'

RSpec.describe MultiItemDeposit::StructureResults do
  subject(:structure_results) { described_class.new(multi_item_deposit_action:) }

  let(:multi_item_deposit_action) { create(:multi_item_deposit_action) }
  let(:image_content) { create(:content, druid: 'druid:bc123df4567') }
  let(:book_content) { create(:content, druid: 'druid:cd234fg5678') }

  describe '#summary' do
    before do
      create(:content_file_binary, content: image_content, filepath: 'image1.tif', mime_type: 'image/tiff', size: 1000)
      create(:content_file_binary, content: image_content, filepath: 'image2.jp2', mime_type: 'image/jp2', size: 2000)
      create(:content_file_binary, content: book_content, filepath: 'page1.tif', mime_type: 'image/tiff', size: 3000)
      create(:content_file_binary, content: book_content, filepath: 'book.pdf', mime_type: 'application/pdf',
                                   size: 4000)
      create(:content_file_binary, content: book_content, filepath: 'unknown.dat', mime_type: nil, size: nil)
      create(:item_deposit_action, multi_item_deposit_action:, content: image_content, manifest_line_number: 2,
                                   structural_csv_errors: ['Row 2: Missing filename'],
                                   content_type_structure_errors: ['Page has more than one image'])
      create(:item_deposit_action, multi_item_deposit_action:, content: book_content, manifest_line_number: 3,
                                   content_type_structure_errors: ['Page has more than one image'])
      create(:item_deposit_action, multi_item_deposit_action:, manifest_line_number: 4,
                                   content_type_structure_warnings: ['No displayable image'])
      create(:item_deposit_action, multi_item_deposit_action:, manifest_line_number: 5)
      # Another Multi-Item Deposit's Item Deposit and files.
      other_content = create(:content, druid: 'druid:df345gh6789')
      create(:content_file_binary, content: other_content, filepath: 'map.xml', mime_type: 'application/xml',
                                   size: 5000)
      create(:item_deposit_action, content: other_content, structural_csv_errors: ['Row 2: Missing filename'])
    end

    it 'counts the Item Deposits and those with structure errors, not counting warnings' do
      expect(structure_results.summary).to have_attributes(item_count: 4, items_with_errors_count: 2)
    end

    it 'counts and totals the size in bytes of the files discovered for the Item Deposits' do
      expect(structure_results.summary).to have_attributes(file_count: 5, file_size: 10_000)
    end

    it 'lists each MIME type of the discovered files once, alphabetically' do
      expect(structure_results.summary.mime_types).to eq(%w[application/pdf image/jp2 image/tiff])
    end
  end

  context 'when no files were discovered' do
    before do
      create(:item_deposit_action, multi_item_deposit_action:, structural_csv_errors: ['Folder is empty'])
    end

    it 'summarizes no files' do
      expect(structure_results.summary).to have_attributes(item_count: 1, items_with_errors_count: 1, file_count: 0,
                                                           file_size: 0, mime_types: [])
    end
  end
end
