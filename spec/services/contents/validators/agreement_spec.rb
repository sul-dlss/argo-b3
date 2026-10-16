# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Contents::Validators::Agreement do
  subject(:result) { described_class.call(content:, dark: true) }

  let(:content) { create(:content, druid: 'druid:bc123df4567') }

  def create_resource(filepaths: ['agreement.pdf'], file_set_type: 'file', label: '', **file_attributes)
    position = content.content_file_sets.count + 1
    content_file_set = create(:content_file_set, content:, file_set_type:, label:, position:)
    filepaths.each.with_index(1) do |filepath, file_position|
      content_file_binary = create(:content_file_binary, content:, filepath:)
      create(:content_file, content_file_set:, content_file_binary:, position: file_position, label: '',
                            view: 'dark', download: 'none', preserve: true, publish: false, shelve: false,
                            **file_attributes)
    end
  end

  context 'when the resources are valid' do
    before do
      create_resource
      create_resource(filepaths: ['agreement2.pdf'])
    end

    it 'has no errors or warnings' do
      expect(result).to have_attributes(errors: [], warnings: [])
    end
  end

  context 'when a resource has more than one file' do
    before { create_resource(filepaths: ['agreement.pdf', 'agreement2.pdf']) }

    it 'has an error' do
      expect(result.errors).to eq(['Resource 1 must have exactly one file.'])
    end
  end

  context 'when a resource has no files' do
    before { create_resource(filepaths: []) }

    it 'has an error' do
      expect(result.errors).to eq(['Resource 1 must have exactly one file.'])
    end
  end

  context 'when a resource is not a file resource' do
    before { create_resource(file_set_type: 'object') }

    it 'has an error' do
      expect(result.errors).to eq(['Resource 1 is not a file resource.'])
    end
  end

  context 'when a resource has a label' do
    before { create_resource(label: 'Deposit agreement') }

    it 'has no errors or warnings' do
      expect(result).to have_attributes(errors: [], warnings: [])
    end
  end

  context 'when a file is not dark' do
    before { create_resource(view: 'world', download: 'world') }

    it 'has an error' do
      expect(result.errors).to eq(['Resource 1 file agreement.pdf is not dark.'])
    end
  end

  context 'when a file is published' do
    before { create_resource(publish: true) }

    it 'has an error' do
      expect(result.errors).to eq(['Resource 1 file agreement.pdf must be preserved and not published.'])
    end
  end

  context 'when a file is not preserved' do
    before { create_resource(preserve: false) }

    it 'has an error' do
      expect(result.errors).to eq(['Resource 1 file agreement.pdf must be preserved and not published.'])
    end
  end

  context 'when a file has a role' do
    before { create_resource(use: 'transcription') }

    it 'has an error' do
      expect(result.errors).to eq(['Resource 1 file agreement.pdf must not have a role.'])
    end
  end
end
