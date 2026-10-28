# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Contents::Validators::HierarchicalFilepaths do
  subject(:result) { described_class.call(content:, dark:) }

  let(:content) { create(:content, druid: 'druid:bc123df4567') }
  let(:dark) { false }
  let(:error) do
    'Hierarchical filepaths are only allowed for the file and geo content types: ' \
      'folder1/image1.tif, folder2/image2.tif.'
  end

  def create_resource(filepath:)
    position = content.content_file_sets.count + 1
    content_file_set = create(:content_file_set, content:, file_set_type: 'image', label: '', position:)
    content_file_binary = create(:content_file_binary, content:, filepath:)
    create(:content_file, content_file_set:, content_file_binary:, label: filepath)
  end

  context 'when there are no hierarchical filepaths' do
    before { create_resource(filepath: 'image1.tif') }

    it 'has no errors or warnings' do
      expect(result).to have_attributes(errors: [], warnings: [])
    end
  end

  context 'when there are hierarchical filepaths' do
    before do
      create_resource(filepath: 'folder1/image1.tif')
      create_resource(filepath: 'image3.tif')
      create_resource(filepath: 'folder2/image2.tif')
    end

    it 'has an error listing the files' do
      expect(result).to have_attributes(errors: [error], warnings: [])
    end

    context 'when dark' do
      let(:dark) { true }

      it 'still has an error' do
        expect(result).to have_attributes(errors: [error], warnings: [])
      end
    end
  end
end
