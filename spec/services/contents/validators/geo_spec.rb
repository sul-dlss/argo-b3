# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Contents::Validators::Geo do
  subject(:result) { described_class.call(content:, dark:) }

  let(:content) { create(:content, druid: 'druid:bc123df4567') }
  let(:dark) { false }

  def create_resource(file_set_type:, label:, filepath:)
    position = content.content_file_sets.count + 1
    content_file_set = create(:content_file_set, content:, file_set_type:, label:, position:)
    content_file_binary = create(:content_file_binary, content:, filepath:)
    create(:content_file, content_file_set:, content_file_binary:, label: filepath)
  end

  context 'when there is one object resource' do
    before do
      create_resource(file_set_type: 'object', label: 'Object 1', filepath: 'data.zip')
      create_resource(file_set_type: 'preview', label: 'Preview 1', filepath: 'preview.jpg')
    end

    it 'has no errors or warnings' do
      expect(result).to have_attributes(errors: [], warnings: [])
    end
  end

  context 'when there are no object resources' do
    before do
      create_resource(file_set_type: 'file', label: 'File 1', filepath: 'data.zip')
    end

    it 'has an error' do
      expect(result).to have_attributes(errors: ['There are no object resources.'], warnings: [])
    end
  end

  context 'when there is more than one object resource' do
    before do
      create_resource(file_set_type: 'object', label: 'Object 1', filepath: 'data.zip')
      create_resource(file_set_type: 'object', label: 'Object 2', filepath: 'data2.zip')
    end

    it 'has an error' do
      expect(result).to have_attributes(errors: ['There is more than one object resource.'], warnings: [])
    end
  end

  context 'when dark' do
    let(:dark) { true }

    context 'when there are no object resources' do
      it 'has a warning instead of an error' do
        expect(result).to have_attributes(errors: [], warnings: ['There are no object resources.'])
      end
    end

    context 'when there is more than one object resource' do
      before do
        create_resource(file_set_type: 'object', label: 'Object 1', filepath: 'data.zip')
        create_resource(file_set_type: 'object', label: 'Object 2', filepath: 'data2.zip')
      end

      it 'has a warning instead of an error' do
        expect(result).to have_attributes(errors: [], warnings: ['There is more than one object resource.'])
      end
    end
  end
end
