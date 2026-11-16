# frozen_string_literal: true

require 'rails_helper'

RSpec.describe DownloadableFiles do
  subject(:downloadable_files) { described_class.new(content:, file_availability:) }

  let(:content) { create(:content) }
  let(:file_availability) { instance_double(FileAvailability) }

  def create_content_file(filepath:, file_set:, position: 1)
    binary = content.content_file_binaries.find_by(filepath:) ||
             create(:content_file_binary, content:, filepath:, size: 4)
    create(:content_file, content_file_set: file_set, content_file_binary: binary, position:)
  end

  before do
    first_file_set = create(:content_file_set, content:, position: 1)
    second_file_set = create(:content_file_set, content:, position: 2)
    create_content_file(filepath: 'image1.tif', file_set: first_file_set)
    create_content_file(filepath: 'image2.tif', file_set: first_file_set, position: 2)
    create_content_file(filepath: 'image1.tif', file_set: second_file_set)
    allow(file_availability).to receive(:available?) { |content_file| content_file.filepath == 'image1.tif' }
  end

  it 'has the available files, once per filepath' do
    expect(downloadable_files.content_files.map(&:filepath)).to eq(['image1.tif'])
    expect(downloadable_files.total_size).to eq(4)
  end

  describe '#too_large?' do
    context 'when the files total no more than the maximum' do
      before { allow(Settings.bulk_actions).to receive(:download_files_max_size).and_return(4) }

      it 'is false' do
        expect(downloadable_files.too_large?).to be false
      end
    end

    context 'when the files total more than the maximum' do
      before { allow(Settings.bulk_actions).to receive(:download_files_max_size).and_return(3) }

      it 'is true' do
        expect(downloadable_files.too_large?).to be true
      end
    end
  end
end
