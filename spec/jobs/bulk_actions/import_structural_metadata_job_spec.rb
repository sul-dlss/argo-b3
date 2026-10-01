# frozen_string_literal: true

require 'rails_helper'

RSpec.describe BulkActions::ImportStructuralMetadataJob do
  subject(:job) { described_class.new(bulk_action:, csv_file:, close_version: false) }

  let(:druid) { 'druid:bc123df4567' }
  let(:bulk_action) { create(:bulk_action) }
  let(:log) { StringIO.new }

  let(:structural) do
    {
      contains: [
        file_set(label: 'Image 1', id: '1', filename: 'image1.tif'),
        file_set(label: 'Image 2', id: '2', filename: 'image2.tif')
      ]
    }
  end
  let(:access) { { view: 'world', download: 'world' } }
  let(:cocina_object) { build(:dro_with_metadata, id: druid).new(access:, structural:) }
  let(:opened_cocina_object) { cocina_object.new(version: 2) }

  # The CSV as exported, which can then be modified.
  let(:exported_csv) { StructureSerializer.as_csv(druid, cocina_object.structural) }
  let(:csv_file) { exported_csv }

  let(:job_items) { [] }

  def file_set(label:, id:, filename:, access: { view: 'world', download: 'world' })
    {
      type: Cocina::Models::FileSetType.image.to_s,
      externalIdentifier: "https://cocina.sul.stanford.edu/fileSet/bc123df4567-#{id}",
      label:,
      version: 1,
      structural: {
        contains: [
          {
            type: Cocina::Models::ObjectType.file.to_s,
            externalIdentifier: "https://cocina.sul.stanford.edu/file/bc123df4567-#{id}",
            label: filename,
            filename:,
            size: 100,
            version: 1,
            hasMimeType: 'image/tiff',
            hasMessageDigests: [
              { type: 'md5', digest: 'b6ce12a1dd5db09f10b51659c83f90a3' },
              { type: 'sha1', digest: 'ff66b3b3dc3ef733d39e949549791ff78754871b' }
            ],
            access:,
            administrative: { publish: true, sdrPreserve: true, shelve: true },
            presentation: { height: 200, width: 100 }
          }
        ]
      }
    }
  end

  before do
    allow(described_class::JobItem).to receive(:new).and_wrap_original do |original, **args|
      original.call(**args).tap do |job_item|
        allow(job_item).to receive(:check_update_ability?).and_return(true)
        allow(job_item).to receive(:open_new_version_if_needed!) do
          job_item.instance_variable_set(:@cocina_object, opened_cocina_object)
        end
        allow(job_item).to receive(:close_version_if_needed!)
        job_items << job_item
      end
    end
    allow(File).to receive(:open).and_call_original
    allow(File).to receive(:open).with(bulk_action.log_filepath, 'a').and_return(log)
    allow(Sdr::Repository).to receive(:find).with(druid:).and_return(cocina_object)
    allow(Sdr::Repository).to receive(:update)
  end

  context 'when the structure is changed' do
    # Reverses the order of the file sets.
    let(:csv_file) do
      lines = exported_csv.lines
      [lines[0], lines[2], lines[1]].join
    end

    it 'updates the object' do
      job.perform_now

      expect(described_class::JobItem).to have_received(:new).with(druid:, index: 2, job:, rows: an_instance_of(Array))
      expect(job_items.first).to have_received(:open_new_version_if_needed!)
        .with(description: 'Updated structural metadata')
      expect(Sdr::Repository).to have_received(:update) do |cocina_object:, user_name:, description:|
        expect(cocina_object.version).to eq(2)
        expect(cocina_object.structural.contains.map(&:label)).to eq(['Image 2', 'Image 1'])
        expect(cocina_object.structural.contains.map(&:externalIdentifier))
          .to eq(%w[https://cocina.sul.stanford.edu/fileSet/bc123df4567-2
                    https://cocina.sul.stanford.edu/fileSet/bc123df4567-1])
        expect(user_name).to eq(bulk_action.user.sunetid)
        expect(description).to eq('Updated structural metadata')
      end
      expect(job_items.first).to have_received(:close_version_if_needed!)

      expect(log.string).to include("line 2\t#{druid}\tSuccess: Updated structural metadata")
      expect(bulk_action.reload.druid_count_total).to eq(1)
      expect(bulk_action.druid_count_success).to eq(1)
      expect(bulk_action.druid_count_fail).to eq(0)
      expect(Content.count).to eq(0)
    end
  end

  context 'when the structure is unchanged' do
    it 'does not update the object' do
      job.perform_now

      expect(job_items.first).not_to have_received(:open_new_version_if_needed!)
      expect(Sdr::Repository).not_to have_received(:update)
      expect(log.string).to include('Success: Structure unchanged')
      expect(bulk_action.reload.druid_count_success).to eq(1)
    end
  end

  context 'when the structure is unchanged but the object has nil values' do
    # For example, an object last updated with an explicit location: nil, which StructuralMutator omits.
    let(:structural) do
      {
        contains: [
          file_set(label: 'Image 1', id: '1', filename: 'image1.tif',
                   access: { view: 'world', download: 'world', location: nil }),
          file_set(label: 'Image 2', id: '2', filename: 'image2.tif')
        ]
      }
    end

    it 'does not update the object' do
      job.perform_now

      expect(Sdr::Repository).not_to have_received(:update)
      expect(log.string).to include('Success: Structure unchanged')
    end
  end

  context 'when the rows are invalid' do
    let(:csv_file) do
      "#{exported_csv}bc123df4567,Image 3,image,3,image3.tif,,yes,yes,yes,world,world,,image/tiff,,,,\n"
    end

    it 'does not update the object and logs the errors' do
      job.perform_now

      expect(Sdr::Repository).not_to have_received(:update)
      expect(log.string).to include('Error: Row 4: image3.tif is not an existing file (files cannot be added)')
      expect(bulk_action.reload.druid_count_fail).to eq(1)
      expect(Content.count).to eq(0)
    end
  end

  context 'when there are rows for multiple druids and rows without a druid' do
    let(:other_druid) { 'druid:fg123hj4589' }
    let(:other_cocina_object) { build(:dro_with_metadata, id: other_druid).new(access:, structural:) }
    let(:csv_file) do
      header, *rows = exported_csv.lines
      other_rows = rows.map { |row| row.sub('bc123df4567', 'fg123hj4589') }
      [header, rows[0], other_rows[0], ",#{rows[1].split(',', 2).last}", "druid:#{rows[1]}", other_rows[1]].join
    end

    before do
      allow(Sdr::Repository).to receive(:find).with(druid: other_druid).and_return(other_cocina_object)
    end

    it 'imports the rows for each druid' do
      job.perform_now

      # Rows with bare and prefixed druids for the same object are grouped together.
      expect(described_class::JobItem).to have_received(:new)
        .with(druid:, index: 2, job:, rows: [[2, anything], [5, anything]])
      expect(described_class::JobItem).to have_received(:new)
        .with(druid: other_druid, index: 3, job:, rows: [[3, anything], [6, anything]])
      expect(log.string).to include("line 4\t\tError: Missing druid")
      expect(bulk_action.reload.druid_count_total).to eq(3)
      expect(bulk_action.druid_count_success).to eq(2)
      expect(bulk_action.druid_count_fail).to eq(1)
    end
  end

  context 'when a required column is missing' do
    let(:csv_file) { exported_csv.lines.map { |line| line.split(',').values_at(0..10, 12..).join(',') }.join }

    it 'fails every druid' do
      job.perform_now

      expect(described_class::JobItem).not_to have_received(:new)
      expect(log.string).to include('Missing required column "rights_location"')
      expect(bulk_action.reload.druid_count_fail).to eq(1)
    end
  end

  context 'when there is an existing mutable content' do
    let!(:existing_content) { create(:content, druid:, lock: cocina_object.lock, immutable: false) }

    it 'destroys it and imports' do
      job.perform_now

      expect(Content.exists?(existing_content.id)).to be false
      expect(bulk_action.reload.druid_count_success).to eq(1)
    end
  end

  context 'when files are being staged for the object' do
    before do
      create(:content, druid:, lock: cocina_object.lock, immutable: false, staging_state: 'staging')
    end

    it 'does not import' do
      job.perform_now

      expect(Sdr::Repository).not_to have_received(:update)
      expect(log.string).to include('Error: Files are being staged or discovered for this object')
      expect(bulk_action.reload.druid_count_fail).to eq(1)
      expect(Content.count).to eq(1)
    end
  end

  context 'when the import raises an error' do
    before do
      allow(StructuralCsv::Import).to receive(:call).and_raise(StandardError, 'Something bad happened')
      allow(Honeybadger).to receive(:notify)
      allow(Rails.logger).to receive(:error)
    end

    it 'records the failure, logs, and notifies Honeybadger' do
      job.perform_now

      expect(log.string).to include("#{druid}\tError: StandardError Something bad happened")
      expect(Rails.logger).to have_received(:error).with(/Something bad happened/)
      expect(Honeybadger).to have_received(:notify).with(instance_of(StandardError))
      expect(bulk_action.reload.druid_count_fail).to eq(1)
    end
  end

  context 'when the object is not an item' do
    let(:cocina_object) { build(:collection_with_metadata, id: druid) }
    let(:csv_file) do
      "#{StructuralCsv::Validator::REQUIRED_COLUMNS.join(',')}\nbc123df4567,1,image1.tif,yes,yes,world,world,\n"
    end

    it 'does not import' do
      job.perform_now

      expect(log.string).to include('Error: Not an item (https://cocina.sul.stanford.edu/models/collection)')
      expect(bulk_action.reload.druid_count_fail).to eq(1)
    end
  end
end
