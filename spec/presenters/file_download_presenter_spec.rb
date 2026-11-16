# frozen_string_literal: true

require 'rails_helper'

RSpec.describe FileDownloadPresenter do
  subject(:presenter) { described_class.new(druid_token: 'abc123', file_availability:) }

  let(:file_availability) { instance_double(FileAvailability, available?: available) }
  let(:content_file) { instance_double(ContentFile, filepath: 'folder 1/image 1.tif') }

  context 'when the file is available' do
    let(:available) { true }

    it 'links to the download endpoint' do
      expect(presenter.link(content_file:)).to eq('/objects/abc123/file_download?filepath=folder+1%2Fimage+1.tif')
    end
  end

  context 'when the file is not available' do
    let(:available) { false }

    it 'returns nil' do
      expect(presenter.link(content_file:)).to be_nil
    end
  end
end
