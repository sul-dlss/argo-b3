# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Contents::UnsavedChangesDiscarder do
  subject(:call) { described_class.call(content:, cocina_object:) }

  let(:druid) { 'druid:bc123df4567' }
  let(:cocina_object) do
    build(:dro_with_metadata, id: druid).new(
      lock: 'druid-version-2',
      access: { view: 'world', download: 'world' },
      structural: {
        contains: [
          cocina_file_set(label: 'Page 1', filenames: %w[page1.tif]),
          cocina_file_set(label: 'Page 2', filenames: %w[page2.tif])
        ]
      }
    )
  end
  let(:content) do
    create(:content, :mutable, druid:, lock: 'druid-version-2', perform_ocr: true, ocr_languages: ['English'])
  end
  let(:staged_filepath) { File.join(Settings.staging_location, 'bc/123/df/4567/bc123df4567/content/page2.tif') }

  def cocina_file_set(label:, filenames:)
    {
      type: Cocina::Models::FileSetType.page,
      externalIdentifier: "#{druid}_#{label.parameterize}",
      label:,
      version: 1,
      structural: { contains: filenames.map { |filename| cocina_file(filename:) } }
    }
  end

  def cocina_file(filename:)
    {
      type: Cocina::Models::ObjectType.file,
      externalIdentifier: "#{druid}_#{filename}",
      label: filename,
      filename:,
      version: 1,
      hasMimeType: 'image/tiff',
      access: { view: 'world', download: 'world' },
      administrative: { publish: true, sdrPreserve: true, shelve: true }
    }
  end

  before do
    # The unsaved changes: page 1 was deleted, page 2 was relabeled, and a file was uploaded.
    content_file_set = create(:content_file_set, content:, label: 'Relabeled', position: 1)
    staged_binary = create(:content_file_binary, content:, file_location: 'stage', filepath: 'page2.tif')
    create(:content_file, content_file_set:, content_file_binary: staged_binary)
    uploaded_binary = create(:content_file_binary, content:, file_location: 'attached', filepath: 'upload.txt')
    uploaded_binary.file.attach(fixture_file_upload('dropzone_upload.txt', 'text/plain'))

    FileUtils.mkdir_p(File.dirname(staged_filepath))
    FileUtils.touch(staged_filepath)
  end

  after do
    FileUtils.rm_rf(StagingSupport.staging_content_path(druid:))
  end

  it 'rebuilds the structure from the cocina object' do
    expect(call).to be true

    content.reload
    expect(content.content_file_sets.map(&:label)).to eq(['Page 1', 'Page 2'])
    expect(content.content_file_binaries.pluck(:filepath)).to contain_exactly('page1.tif', 'page2.tif')
  end

  it 'marks the files staged in the open version as staged' do
    call

    expect(content.content_file_binaries.find_by(filepath: 'page2.tif').file_location).to eq('stage')
    expect(content.content_file_binaries.find_by(filepath: 'page1.tif').file_location).to eq('deposited')
  end

  it 'returns to the first step of managing files and clears the item details' do
    content.update!(step: 'structure', content_type: Cocina::Models::ObjectType.image)

    call

    expect(content.reload).to have_attributes(step: 'details', content_type: nil)
  end

  it 'keeps the content and its text extraction settings' do
    call

    expect(content.reload).to have_attributes(lock: 'druid-version-2', immutable: false, perform_ocr: true,
                                              ocr_languages: ['English'])
  end

  it 'purges the uploads' do
    expect { call }.to have_enqueued_job(ActiveStorage::PurgeJob)
  end

  context 'when the object has changed since manage files was opened' do
    let(:content) { create(:content, :mutable, druid:, lock: 'druid-version-1') }

    it 'does not discard' do
      expect(call).to be false
      expect(content.content_file_sets.map(&:label)).to eq(['Relabeled'])
    end
  end

  context 'when the content is immutable' do
    let(:content) { create(:content, druid:, lock: 'druid-version-2') }

    it 'does not discard' do
      expect(call).to be false
      expect(content.content_file_sets.map(&:label)).to eq(['Relabeled'])
    end
  end

  context 'when the content is staging' do
    let(:content) { create(:content, :mutable, druid:, lock: 'druid-version-2', staging_state: 'staging') }

    it 'raises without discarding' do
      expect { call }.to raise_error(described_class::ContentBusyError)
      expect(content.content_file_sets.map(&:label)).to eq(['Relabeled'])
    end
  end

  context 'when staging the content failed' do
    let(:content) { create(:content, :mutable, druid:, lock: 'druid-version-2', staging_state: 'staging_failed') }

    it 'raises without discarding' do
      expect { call }.to raise_error(described_class::StagingFailedError)
      expect(content.content_file_sets.map(&:label)).to eq(['Relabeled'])
    end
  end
end
