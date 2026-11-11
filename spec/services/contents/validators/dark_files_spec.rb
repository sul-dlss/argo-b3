# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Contents::Validators::DarkFiles do
  subject(:result) { described_class.call(content:, dark: true) }

  let(:content) { create(:content, druid: 'druid:bc123df4567') }
  let(:content_file_set) { create(:content_file_set, content:, file_set_type: 'page', label: 'Page 1') }
  let(:content_file_binary) { create(:content_file_binary, content:, filepath: 'page_0001.tif') }
  let(:file_attributes) { {} }

  before do
    create(:content_file, content_file_set:, content_file_binary:, view: 'dark', download: 'none',
                          publish: false, shelve: false, **file_attributes)
  end

  context 'when the files are dark and unpublished' do
    it 'has no errors or warnings' do
      expect(result).to have_attributes(errors: [], warnings: [])
    end
  end

  context 'when a file is not dark' do
    let(:file_attributes) { { view: 'world', download: 'world' } }

    it 'has an error' do
      expect(result.errors).to eq(['Resource 1 (Page 1) file page_0001.tif must be dark because the object is dark.'])
    end
  end

  context 'when a file is published' do
    let(:file_attributes) { { publish: true } }

    it 'has an error' do
      expect(result.errors)
        .to eq(['Resource 1 (Page 1) file page_0001.tif must not be published or shelved because the object is dark.'])
    end
  end

  context 'when a file is shelved' do
    let(:file_attributes) { { shelve: true } }

    it 'has an error' do
      expect(result.errors)
        .to eq(['Resource 1 (Page 1) file page_0001.tif must not be published or shelved because the object is dark.'])
    end
  end
end
