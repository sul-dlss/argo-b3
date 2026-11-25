# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Reports::ContentErrorsSliceChecker do
  subject(:rows) { described_class.call(druids:) }

  let(:druids) { [druid, other_druid] }
  let(:druid) { 'druid:bc123df4567' }
  let(:other_druid) { 'druid:hj456km7891' }
  let(:cocina_object) { build_cocina(druid:, filenames: ['folder1/page1.tif']) }
  let(:other_cocina_object) { build_cocina(druid: other_druid, filenames: ['page1.tif']) }
  let(:hierarchical_error) do
    'Hierarchical filepaths are only allowed for the file and geo content types: folder1/page1.tif.'
  end

  before do
    allow(Sdr::Repository).to receive(:find_all)
      .and_return(druid => cocina_object, other_druid => other_cocina_object)
    allow(Sdr::Repository).to receive(:find)
    allow(Sdr::VersionService).to receive(:statuses).and_return({})
  end

  def build_cocina(druid:, filenames:, type: Cocina::Models::ObjectType.book, access: 'world')
    build(:dro_with_metadata, id: druid, type:).new(
      access: { view: access, download: access == 'dark' ? 'none' : access },
      structural: { contains: filenames.map { |filename| cocina_file_set(druid:, filename:, access:) } }
    )
  end

  def cocina_file_set(druid:, filename:, access:)
    published = access != 'dark'
    {
      type: Cocina::Models::FileSetType.page, externalIdentifier: "#{druid}_#{filename.parameterize}",
      label: 'Page 1', version: 1,
      structural: {
        contains: [{ type: Cocina::Models::ObjectType.file, externalIdentifier: "#{druid}_#{filename}",
                     label: filename, filename:, version: 1, hasMimeType: 'image/tiff',
                     access: { view: access, download: published ? access : 'none' },
                     administrative: { publish: published, sdrPreserve: true, shelve: published } }]
      }
    }
  end

  def version_status(version:, open:)
    Dor::Services::Client::ObjectVersion::VersionStatus.new(versionId: version, open:, openable: !open,
                                                            assembling: false, accessioning: false,
                                                            closeable: open, discardable: false,
                                                            versionDescription: 'A version')
  end

  it 'returns a row for each object with errors, retrieving the objects together' do
    expect(rows).to eq([['bc123df4567', 'book', hierarchical_error]])
    expect(Sdr::Repository).to have_received(:find_all).with(druids:)
    expect(Sdr::Repository).not_to have_received(:find)
  end

  context 'when an object has several errors' do
    let(:cocina_object) do
      build_cocina(druid:, filenames: ['folder1/page1.tif'], type: Cocina::Models::ObjectType.image)
    end

    it 'joins the errors with spaces' do
      expect(rows).to eq([['bc123df4567', 'image',
                           'Resource 1 (Page 1) has published files but is not an image or object resource. ' \
                           "#{hierarchical_error}"]])
    end
  end

  context 'when an object has only warnings' do
    # Dark, so that the violations of the book model are warnings.
    let(:cocina_object) { build_cocina(druid:, filenames: ['page1.txt'], access: 'dark') }

    it 'returns no row' do
      expect(rows).to eq([])
    end
  end

  context 'when an object has no files' do
    let(:cocina_object) { build_cocina(druid:, filenames: [], type: Cocina::Models::ObjectType.geo) }

    before do
      allow(Sdr::VersionService).to receive(:statuses).and_return(druid => status)
    end

    context 'when it is Registered (an open first version)' do
      let(:status) { version_status(version: 1, open: true) }

      it 'skips it, retrieving the statuses of only the objects without files' do
        expect(rows).to eq([])
        expect(Sdr::VersionService).to have_received(:statuses).with(druids: [druid])
      end
    end

    context 'when it has been deposited' do
      let(:status) { version_status(version: 2, open: true) }

      it 'returns a row for its errors' do
        expect(rows).to eq([['bc123df4567', 'geo', 'There are no object resources.']])
      end
    end
  end

  context 'when retrieving the version statuses fails' do
    let(:cocina_object) { build_cocina(druid:, filenames: [], type: Cocina::Models::ObjectType.geo) }

    before do
      allow(Sdr::VersionService).to receive(:statuses).and_raise(Sdr::VersionService::Error, 'Retrieving failed')
    end

    it 'returns a row for each object without files that could not be checked' do
      expect(rows).to eq([['bc123df4567', 'geo', 'Could not be checked']])
      expect(Sdr::VersionService).to have_received(:statuses).once
    end
  end

  context 'when retrieving the objects together fails' do
    before do
      allow(Sdr::Repository).to receive(:find_all).and_raise(Dor::Services::Client::UnexpectedResponse,
                                                             'Invalid cocina')
      allow(Sdr::Repository).to receive(:find).with(druid:)
                                              .and_raise(Sdr::Repository::InvalidCocinaError, 'Invalid cocina')
      allow(Sdr::Repository).to receive(:find).with(druid: other_druid)
                                              .and_return(build_cocina(druid: other_druid,
                                                                       filenames: ['folder1/page1.tif']))
    end

    it 'retrieves the objects one at a time, returning a row for each that could not be checked' do
      expect(rows).to eq([['bc123df4567', nil, 'Could not be checked'],
                          ['hj456km7891', 'book', hierarchical_error]])
      expect(Sdr::Repository).to have_received(:find).with(druid:).once
    end
  end

  context 'when an object is missing from the objects retrieved together' do
    before do
      allow(Sdr::Repository).to receive(:find_all).and_return(other_druid => other_cocina_object)
      allow(Sdr::Repository).to receive(:find).with(druid:)
                                              .and_raise(Sdr::Repository::NotFoundResponse, 'Object not found')
    end

    it 'returns a row for it that could not be checked' do
      expect(rows).to eq([['bc123df4567', nil, 'Could not be checked']])
    end
  end
end
