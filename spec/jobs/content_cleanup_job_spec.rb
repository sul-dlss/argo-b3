# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ContentCleanupJob do
  include ActiveJob::TestHelper

  subject(:job) { described_class.new }

  let(:druid) { 'druid:bc123df4567' }
  let(:other_druid) { 'druid:gh456jk7832' }
  let(:current_lock) { 'druid-version-2' }
  let(:stale_lock) { 'druid-version-1' }

  before do
    allow(Sdr::Repository).to receive(:lock).and_return(current_lock)
  end

  def create_old_content(**)
    create(:content, created_at: 4.days.ago, **)
  end

  context 'when an old content has a stale lock' do
    let!(:content) { create_old_content(druid:, lock: stale_lock, immutable: false) }
    let!(:content_file) { create(:content_file, content_file_set: create(:content_file_set, content:)) }

    before do
      content_file.content_file_binary.file.attach(fixture_file_upload('dropzone_upload.txt', 'text/plain'))
    end

    it 'deletes the content, file sets, files, binaries, and attached files' do
      perform_enqueued_jobs { job.perform }

      expect(Sdr::Repository).to have_received(:lock).with(druid:)
      expect(Content.count).to eq(0)
      expect(ContentFileSet.count).to eq(0)
      expect(ContentFile.count).to eq(0)
      expect(ContentFileBinary.count).to eq(0)
      expect(ActiveStorage::Attachment.count).to eq(0)
      expect(ActiveStorage::Blob.count).to eq(0)
    end
  end

  context 'when a binary for a stale content has been staged' do
    let(:staging_filepath) do
      File.join(Settings.staging_location, 'bc/123/df/4567/bc123df4567/content/image1.tif')
    end

    before do
      content = create_old_content(druid:, lock: stale_lock, immutable: false)
      create(:content_file_binary, content:, file_location: 'stage', filepath: 'image1.tif')
      FileUtils.mkdir_p(File.dirname(staging_filepath))
      FileUtils.touch(staging_filepath)
    end

    after do
      FileUtils.rm_rf(File.join(Settings.staging_location, 'bc'))
    end

    it 'deletes the binary but not the staged file' do
      job.perform

      expect(ContentFileBinary.count).to eq(0)
      expect(File.exist?(staging_filepath)).to be true
    end
  end

  context 'when an old content has the current lock' do
    let!(:content) { create_old_content(druid:, lock: current_lock) }

    it 'keeps the content' do
      job.perform

      expect(Content.all).to contain_exactly(content)
    end
  end

  context 'when a content is not old enough' do
    let!(:content) { create(:content, druid:, lock: stale_lock, created_at: 2.days.ago) }

    it 'keeps the content without retrieving the lock' do
      job.perform

      expect(Content.all).to contain_exactly(content)
      expect(Sdr::Repository).not_to have_received(:lock)
    end
  end

  context 'when old contents with stale locks are staging or discovering' do
    let!(:staging_content) { create_old_content(druid:, lock: stale_lock, staging_state: 'staging') }
    let!(:discovering_content) do
      create_old_content(druid: other_druid, lock: stale_lock, mount_state: 'discovering')
    end

    it 'keeps the contents' do
      job.perform

      expect(Content.all).to contain_exactly(staging_content, discovering_content)
    end
  end

  context 'when a druid has a stale content and a current content' do
    let!(:current_content) { create_old_content(druid:, lock: current_lock, immutable: false) }

    before do
      create_old_content(druid:, lock: stale_lock, immutable: true)
    end

    it 'deletes only the stale content and retrieves the lock once' do
      job.perform

      expect(Content.all).to contain_exactly(current_content)
      expect(Sdr::Repository).to have_received(:lock).once.with(druid:)
    end
  end

  context 'when the object is not found' do
    before do
      allow(Sdr::Repository).to receive(:lock).and_raise(Sdr::Repository::NotFoundResponse)
      create_old_content(druid:, lock: current_lock)
    end

    it 'deletes the content' do
      job.perform

      expect(Content.count).to eq(0)
    end
  end

  context 'when retrieving the lock fails for a druid' do
    let(:error) { Sdr::Repository::Error.new('DSA unavailable') }
    let!(:failed_content) { create_old_content(druid:, lock: stale_lock) }

    before do
      allow(Sdr::Repository).to receive(:lock).with(druid:).and_raise(error)
      allow(Honeybadger).to receive(:notify)
      create_old_content(druid: other_druid, lock: stale_lock)
    end

    it 'notifies and continues with the other druids' do
      job.perform

      expect(Content.all).to contain_exactly(failed_content)
      expect(Honeybadger).to have_received(:notify).with(error, context: { druid: })
    end
  end
end
