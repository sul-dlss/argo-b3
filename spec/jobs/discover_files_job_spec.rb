# frozen_string_literal: true

require 'rails_helper'

RSpec.describe DiscoverFilesJob do
  subject(:job) { described_class.new }

  let(:content) { create(:content, druid: 'druid:bc123df4567', mount_state: 'discovering') }
  let(:mount_path) { Dir.mktmpdir }

  before do
    File.write(File.join(mount_path, 'file1.txt'), 'file one')
  end

  after do
    FileUtils.rm_rf(mount_path)
  end

  describe '#perform' do
    it 'creates mount binaries for the files on the mount' do
      job.perform(content:, mount_path:)

      expect(content.content_file_binaries.find_by(filepath: 'file1.txt'))
        .to have_attributes(file_location: 'mount', mount_path:, size: 8, mime_type: 'text/plain')
    end

    it 'creates binaries with the given file location' do
      job.perform(content:, mount_path:, file_location: :globus)

      expect(content.content_file_binaries.find_by(filepath: 'file1.txt'))
        .to have_attributes(file_location: 'globus', mount_path:)
    end

    it 'transitions the content out of the discovering state' do
      job.perform(content:, mount_path:)

      expect(content.reload.mount_state).to eq('discovery_not_in_progress')
    end
  end
end
