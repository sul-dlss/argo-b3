# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Contents::Validators::DarkPublishedFiles do
  subject(:result) { described_class.call(content:, dark:) }

  let(:content) { create(:content, druid: 'druid:bc123df4567') }
  let(:dark) { false }
  let(:warning) { 'Files are dark but published: image1.tif, folder1/image3.tif.' }

  def create_resource(filepath:, view: 'world', download: 'world', publish: true)
    position = content.content_file_sets.count + 1
    content_file_set = create(:content_file_set, content:, file_set_type: 'image', label: '', position:)
    content_file_binary = create(:content_file_binary, content:, filepath:)
    create(:content_file, content_file_set:, content_file_binary:, label: filepath, view:, download:, publish:)
  end

  context 'when no files are dark and published' do
    before do
      create_resource(filepath: 'image1.tif', view: 'dark', download: 'none', publish: false)
      create_resource(filepath: 'image2.tif')
    end

    it 'has no errors or warnings' do
      expect(result).to have_attributes(errors: [], warnings: [])
    end
  end

  context 'when files are dark and published' do
    before do
      create_resource(filepath: 'image1.tif', view: 'dark', download: 'none')
      create_resource(filepath: 'image2.tif')
      create_resource(filepath: 'folder1/image3.tif', view: 'dark', download: 'none')
    end

    it 'has a warning listing the files' do
      expect(result).to have_attributes(errors: [], warnings: [warning])
    end

    context 'when dark' do
      let(:dark) { true }

      it 'still has a warning' do
        expect(result).to have_attributes(errors: [], warnings: [warning])
      end
    end
  end
end
