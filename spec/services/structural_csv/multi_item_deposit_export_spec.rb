# frozen_string_literal: true

require 'rails_helper'

RSpec.describe StructuralCsv::MultiItemDepositExport do
  subject(:csv) { described_class.as_csv(multi_item_deposit_action:) }

  let(:multi_item_deposit_action) { create(:multi_item_deposit_action) }

  context 'with Item Deposits whose structures were and were not built' do
    let(:built_content) { create(:content, :mutable, druid: 'druid:bc123df4567') }
    let(:unbuilt_content) { create(:content, :mutable, druid: 'druid:fg123hj4589') }
    let(:failed_content) { create(:content, :mutable, druid: 'druid:km123mn4512') }

    before do
      create(:item_deposit_action, multi_item_deposit_action:, druid: 'druid:fg123hj4589', manifest_line_number: 3,
                                   content: unbuilt_content, structural_csv_errors: ['Row 2: Missing filename'])
      create(:item_deposit_action, multi_item_deposit_action:, druid: 'druid:bc123df4567', manifest_line_number: 2,
                                   content: built_content, content_type_structure_errors: ['A book error'],
                                   file_changes: { 'added' => 1, 'deleted' => 0, 'updated' => 0 })
      # An unexpected error clears the file changes.
      create(:item_deposit_action, multi_item_deposit_action:, druid: 'druid:km123mn4512', manifest_line_number: 4,
                                   content: failed_content, content_type_structure_errors: ['Unexpected'])
      create(:item_deposit_action, multi_item_deposit_action:, druid: 'druid:pq123rs4567', manifest_line_number: 5)

      content_file_set = create(:content_file_set, content: built_content, label: 'Page 1', file_set_type: 'page')
      create(:content_file, content_file_set:, label: 'Image 1', publish: false,
                            content_file_binary: create(:content_file_binary, content: built_content,
                                                                              filepath: 'image1.tif',
                                                                              mime_type: 'image/tiff'))
      create(:content_file_binary, content: unbuilt_content, filepath: 'folder1/document.pdf',
                                   mime_type: 'application/pdf')
      create(:content_file_binary, content: failed_content, filepath: 'image3.tif', mime_type: 'image/tiff')
    end

    it 'returns the built structures and template rows for the other Item Deposits with a Content' do
      expect(csv).to eq(<<~CSV)
        druid,resource_label,resource_type,sequence,filename,file_label,publish,shelve,preserve,rights_view,rights_download,rights_location,mimetype,role,file_language,sdr_generated_text,corrected_for_accessibility
        bc123df4567,Page 1,page,1,image1.tif,Image 1,no,yes,yes,world,world,,image/tiff,,,false,false
        fg123hj4589,,,,folder1/document.pdf,,,,,,,,application/pdf,,,,
        km123mn4512,,,,image3.tif,,,,,,,,image/tiff,,,,
      CSV
    end
  end

  describe 'uploading the downloaded CSV again' do
    let(:content) { create(:content, :mutable, druid: 'druid:bc123df4567') }
    let!(:item_deposit_action) do
      create(:item_deposit_action, multi_item_deposit_action:, druid: manifest_druid, content:, content_type: 'book')
    end
    let(:cocina_object) do
      build(:dro_with_metadata, id: 'druid:bc123df4567', type: Cocina::Models::ObjectType.book)
    end

    def structure
      MultiItemDeposit::StructureJob.perform_now(item_deposit_action:)
      item_deposit_action.reload
      content.reload.content_file_sets.map do |content_file_set|
        content_files = content_file_set.content_files.map do |content_file|
          content_file.attributes.except('id', 'created_at', 'updated_at', 'content_file_set_id')
        end
        [content_file_set.label, content_file_set.file_set_type, content_files]
      end
    end

    before do
      create(:content_file_binary, content:, filepath: 'page1.tif', basename: 'page1', mime_type: 'image/tiff')
      create(:content_file_binary, content:, filepath: 'page2.tif', basename: 'page2', mime_type: 'image/tiff')
      allow(Sdr::Repository).to receive(:find).and_return(cocina_object)
    end

    %w[druid:bc123df4567 bc123df4567].each do |druid|
      context "when the manifest has the druid #{druid}" do
        let(:manifest_druid) { druid }

        it 'builds the same structure' do
          built_structure = structure
          expect(item_deposit_action.structure_built?).to be true
          expect(built_structure.map(&:first)).to eq(['Page 1', 'Page 2'])

          multi_item_deposit_action.update!(structural_metadata_csv: csv)
          expect(structure).to eq(built_structure)
          expect(item_deposit_action.structural_csv_errors).to eq([])
        end
      end
    end
  end

  context 'when uploading template rows again' do
    let(:content) { create(:content, :mutable, druid: 'druid:bc123df4567') }
    let!(:item_deposit_action) do
      create(:item_deposit_action, multi_item_deposit_action:, druid: 'druid:bc123df4567', content:,
                                   content_type: 'book', structural_csv_errors: ['Row 2: Missing filename'])
    end

    before do
      create(:content_file_binary, content:, filepath: 'page1.tif', basename: 'page1', mime_type: 'image/tiff')
      allow(Sdr::Repository).to receive(:find)
        .and_return(build(:dro_with_metadata, id: 'druid:bc123df4567', type: Cocina::Models::ObjectType.book))
    end

    it 'gives structural CSV errors' do
      multi_item_deposit_action.update!(structural_metadata_csv: csv)
      MultiItemDeposit::StructureJob.perform_now(item_deposit_action:)

      expect(item_deposit_action.reload.structural_csv_errors).not_to be_empty
    end
  end
end
