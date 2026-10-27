# frozen_string_literal: true

require 'rails_helper'

RSpec.describe GlobusDirectory do
  subject(:globus_directory) { described_class.new(druid: 'druid:bc123df4567', user:) }

  let(:user) { create(:user, email_address: 'jdoe@stanford.edu') }
  let(:object_path) { '/uploads/jdoe/objects/bc123df4567' }
  let(:local_path) { File.join(Settings.globus.directory, object_path) }

  after do
    FileUtils.rm_rf(Settings.globus.directory)
  end

  describe '#object_path' do
    it 'returns the endpoint path for the user and object' do
      expect(globus_directory.object_path).to eq(object_path)
    end
  end

  describe '#local_path' do
    it 'returns the path on the Globus mount' do
      expect(globus_directory.local_path).to eq(local_path)
    end
  end

  describe '#url' do
    it 'returns a Globus file manager link with the directory as the destination' do
      expect(globus_directory.url)
        .to eq('https://app.globus.org/file-manager?destination_id=endpoint_id' \
               '&destination_path=%2Fuploads%2Fjdoe%2Fobjects%2Fbc123df4567')
    end
  end

  describe '#writable?' do
    before do
      allow(GlobusClient).to receive(:writable?).and_return(true)
    end

    it 'checks with Globus whether the user can write to the directory' do
      expect(globus_directory.writable?).to be true

      expect(GlobusClient).to have_received(:writable?).with(path: object_path, user_id: 'jdoe@stanford.edu')
    end

    context 'when Globus returns an error' do
      let(:error) { GlobusClient::ServiceUnavailable.new }

      before do
        allow(GlobusClient).to receive(:writable?).and_raise(error)
        allow(Honeybadger).to receive(:notify)
      end

      it 'notifies Honeybadger and returns false' do
        expect(globus_directory.writable?).to be false

        expect(Honeybadger).to have_received(:notify).with(error, context: { druid: 'druid:bc123df4567' })
      end
    end

    context 'when in test mode in development' do
      before do
        allow(Settings.globus).to receive(:test_mode).and_return(true)
        allow(Rails.env).to receive(:development?).and_return(true)
      end

      it 'returns false when the local directory does not exist' do
        expect(globus_directory.writable?).to be false
        expect(GlobusClient).not_to have_received(:writable?)
      end

      it 'returns true when the local directory exists' do
        FileUtils.mkdir_p(local_path)

        expect(globus_directory.writable?).to be true
      end
    end
  end

  describe '#create' do
    before do
      allow(GlobusClient).to receive(:mkdir)
    end

    it 'creates the directory on Globus with write access for the user' do
      expect(globus_directory.create).to be true

      expect(GlobusClient).to have_received(:mkdir)
        .with(path: object_path, user_id: 'jdoe@stanford.edu', notify_email: false)
    end

    context 'when Globus returns an error' do
      let(:error) { GlobusClient::ForbiddenError.new }

      before do
        allow(GlobusClient).to receive(:mkdir).and_raise(error)
        allow(Honeybadger).to receive(:notify)
      end

      it 'notifies Honeybadger and returns false' do
        expect(globus_directory.create).to be false

        expect(Honeybadger).to have_received(:notify).with(error, context: { druid: 'druid:bc123df4567' })
      end
    end

    context 'when in test mode in development' do
      before do
        allow(Settings.globus).to receive(:test_mode).and_return(true)
        allow(Rails.env).to receive(:development?).and_return(true)
      end

      it 'creates the local directory instead' do
        expect(globus_directory.create).to be true

        expect(GlobusClient).not_to have_received(:mkdir)
        expect(File.directory?(local_path)).to be true
      end
    end
  end
end
