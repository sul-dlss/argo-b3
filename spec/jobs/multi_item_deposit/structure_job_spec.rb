# frozen_string_literal: true

require 'rails_helper'

RSpec.describe MultiItemDeposit::StructureJob do
  subject(:job) { described_class.new }

  let(:druid) { 'druid:bc123df4567' }
  let(:other_druid) { 'druid:dg321fh7654' }
  let(:structural_metadata_csv) { nil }
  let(:publish_preserve_all) { false }
  let(:multi_item_deposit_action) do
    create(:multi_item_deposit_action, structural_metadata_csv:, publish_preserve_all:)
  end
  let(:content) { create(:content, druid:, immutable: false) }
  let(:content_type) { 'book' }
  let(:item_deposit_action) do
    create(:item_deposit_action, multi_item_deposit_action:, druid:, content:, content_type:,
                                 structural_csv_errors: ['Old CSV error'],
                                 content_type_structure_errors: ['Old error'],
                                 content_type_structure_warnings: ['Old warning'],
                                 file_changes: { 'added' => 9 })
  end
  let(:access) { { view: 'world', download: 'world' } }
  let(:cocina_object) { build(:dro_with_metadata, id: druid, type: Cocina::Models::ObjectType.book).new(access:) }

  before do
    create(:content_file_binary, content:, filepath: 'page1.tif', basename: 'page1', mime_type: 'image/tiff')
    create(:content_file_binary, content:, filepath: 'page2.tif', basename: 'page2', mime_type: 'image/tiff')
    allow(Sdr::Repository).to receive(:find).and_return(cocina_object)
  end

  def perform
    job.perform(item_deposit_action:)
    item_deposit_action.reload
  end

  def file_set_summary
    content.reload.content_file_sets.map do |content_file_set|
      [content_file_set.file_set_type, content_file_set.content_files.map(&:filepath)]
    end
  end

  context 'when there is no structural metadata CSV' do
    it 'structures with the populator for the content type and validates' do
      perform

      expect(file_set_summary).to eq([['page', ['page1.tif']], ['page', ['page2.tif']]])
      expect(item_deposit_action).to have_attributes(structural_csv_errors: [], content_type_structure_errors: [],
                                                     content_type_structure_warnings: [],
                                                     file_changes: { 'added' => 2, 'deleted' => 0,
                                                                     'updated' => 0 })
      expect(Sdr::Repository).to have_received(:find).with(druid:)
    end
  end

  context 'when the stored content type differs from the object type' do
    let(:content_type) { 'object' }

    it 'structures with the populator for the stored content type' do
      perform

      expect(file_set_summary).to eq([['file', ['page1.tif']], ['file', ['page2.tif']]])
    end
  end

  context 'when there are existing file sets' do
    before do
      content_file_set = create(:content_file_set, content:, file_set_type: 'file', label: 'Existing')
      create(:content_file, content_file_set:, content_file_binary: content.content_file_binaries.first)
    end

    it 'discards them' do
      perform

      expect(content.reload.content_file_sets.pluck(:label)).to eq(['Page 1', 'Page 2'])
    end
  end

  context 'when publish_preserve_all' do
    let(:publish_preserve_all) { true }
    let(:content_type) { 'object' }

    before do
      create(:content_file_binary, content:, filepath: 'notes.txt', basename: 'notes', extname: '.txt',
                                   mime_type: 'text/plain')
    end

    it 'publishes, preserves, and shelves every file' do
      perform

      expect(content.reload.content_files.pluck(:publish, :preserve, :shelve).uniq).to eq([[true, true, true]])
    end
  end

  context 'when the structure is not valid for the content type' do
    let(:structural_metadata_csv) do
      <<~CSV
        druid,sequence,resource_type,filename,publish,preserve,rights_view,rights_download,rights_location
        #{druid},1,page,page1.tif,no,yes,world,world,
        #{druid},1,page,page2.tif,no,yes,world,world,
      CSV
    end

    it 'records the content type structure errors and the file changes' do
      perform

      expect(item_deposit_action).to have_attributes(
        content_type_structure_errors: ['Resource 1 has more than one TIFF, PNG, or JPEG file.'],
        file_changes: { 'added' => 2, 'deleted' => 0, 'updated' => 0 }
      )
    end
  end

  context 'when the object has existing structural metadata' do
    let(:cocina_object) do
      build(:dro_with_metadata, id: druid, type: Cocina::Models::ObjectType.book)
        .new(access:, structural: { contains: [file_set('page1.tif'), file_set('old.tif')] })
    end

    def file_set(filename)
      {
        type: Cocina::Models::FileSetType.page,
        externalIdentifier: "#{druid}_#{filename}",
        label: filename,
        version: 1,
        structural: {
          contains: [
            {
              type: Cocina::Models::ObjectType.file,
              externalIdentifier: "#{druid}_#{filename}_file",
              label: filename,
              filename:,
              version: 1,
              hasMessageDigests: [],
              access: { view: 'world', download: 'world' },
              administrative: { publish: true, sdrPreserve: true, shelve: true }
            }
          ]
        }
      }
    end

    it 'records the added, deleted, and updated files' do
      expect(perform.file_changes).to eq({ 'added' => 1, 'deleted' => 1, 'updated' => 1 })
    end
  end

  context 'when there is a structural metadata CSV' do
    let(:publish_preserve_all) { true }
    let(:structural_metadata_csv) do
      <<~CSV
        druid,sequence,resource_type,filename,publish,preserve,rights_view,rights_download,rights_location
        #{druid},1,page,page2.tif,no,yes,world,world,
        #{other_druid},1,page,other.tif,yes,yes,world,world,
        #{druid},2,page,page1.tif,no,yes,world,world,
      CSV
    end

    it 'imports the rows for the object (ignoring publish_preserve_all)' do
      perform

      expect(file_set_summary).to eq([['page', ['page2.tif']], ['page', ['page1.tif']]])
      expect(content.content_files.pluck(:publish, :preserve)).to eq([[false, true], [false, true]])
      expect(item_deposit_action).to have_attributes(structural_csv_errors: [], content_type_structure_errors: [],
                                                     file_changes: { 'added' => 2, 'deleted' => 0,
                                                                     'updated' => 0 })
    end
  end

  context 'when the structural metadata CSV rows are invalid' do
    let(:structural_metadata_csv) do
      <<~CSV
        druid,sequence,filename,publish,preserve,rights_view,rights_download,rights_location
        #{other_druid},1,other.tif,yes,yes,world,world,
        #{druid},1,page1.tif,maybe,yes,world,world,
        #{druid},2,page2.tif,yes,yes,world,world,
      CSV
    end

    it 'records the errors with their rows in the CSV and does not structure' do
      perform

      expect(item_deposit_action).to have_attributes(
        structural_csv_errors: ['Row 3: Value for "publish" ("maybe") must be yes, no, true, or false'],
        content_type_structure_errors: [], content_type_structure_warnings: [], file_changes: {}
      )
      expect(content.reload.content_file_sets).to be_empty
    end
  end

  context 'when the structural metadata CSV has no rows for the object' do
    let(:structural_metadata_csv) do
      <<~CSV
        druid,sequence,filename,publish,preserve,rights_view,rights_download,rights_location
        #{other_druid},1,other.tif,yes,yes,world,world,
      CSV
    end

    it 'records an error' do
      expect(perform.structural_csv_errors).to eq(['No rows for this object in the structural metadata CSV'])
    end
  end

  context 'when discovered files are not in the structural metadata CSV' do
    let(:structural_metadata_csv) do
      <<~CSV
        druid,sequence,filename,publish,preserve,rights_view,rights_download,rights_location
        #{druid},1,page1.tif,yes,yes,world,world,
      CSV
    end

    it 'records an error and retains the files' do
      expect(perform.structural_csv_errors).to eq(['Files not in structural metadata CSV: page2.tif'])
      expect(content.reload.content_file_binaries.pluck(:filepath)).to contain_exactly('page1.tif', 'page2.tif')
      expect(content.content_file_sets).to be_empty
    end
  end

  context 'when an unexpected error occurs' do
    before do
      allow(Contents::Validator).to receive(:call).and_raise(StandardError, 'Boom')
      allow(Honeybadger).to receive(:notify)
    end

    it 'records an error' do
      expect(perform).to have_attributes(
        structural_csv_errors: [],
        content_type_structure_errors: ['An unexpected error occurred while building the structure. ' \
                                        'Contact SDR support for assistance.'],
        content_type_structure_warnings: [], file_changes: {}
      )
      expect(Honeybadger).to have_received(:notify).with(an_instance_of(StandardError))
    end
  end
end
