# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Contents::ExternalIdentifierMinter do
  subject(:call) { described_class.call(content:) }

  let(:content) { create(:content, druid: 'druid:bc123df4567') }

  describe '#call' do
    context 'when the file set and file are missing external identifiers' do
      let(:content_file_set) { create(:content_file_set, content:, external_identifier: nil) }
      let(:content_file) { create(:content_file, content_file_set:, external_identifier: nil) }

      before { content_file }

      it 'mints external identifiers for both' do
        call

        expect(content_file_set.reload.external_identifier).to match(
          %r{\Ahttps://cocina\.sul\.stanford\.edu/fileSet/bc123df4567-[0-9a-f-]{36}\z}
        )
        expect(content_file.reload.external_identifier).to match(
          %r{\Ahttps://cocina\.sul\.stanford\.edu/file/bc123df4567-[0-9a-f-]{36}\z}
        )
      end
    end

    context 'when the file set already has an external identifier' do
      let(:content_file_set) do
        create(:content_file_set, content:, external_identifier: 'https://cocina.sul.stanford.edu/fileSet/existing')
      end

      before { create(:content_file, content_file_set:, external_identifier: nil) }

      it 'does not change the file set external identifier' do
        call

        expect(content_file_set.reload.external_identifier).to eq('https://cocina.sul.stanford.edu/fileSet/existing')
      end
    end

    context 'when the file already has an external identifier' do
      let(:content_file_set) { create(:content_file_set, content:, external_identifier: nil) }
      let(:content_file) do
        create(:content_file, content_file_set:, external_identifier: 'https://cocina.sul.stanford.edu/file/existing')
      end

      before { content_file }

      it 'does not change the file external identifier' do
        call

        expect(content_file.reload.external_identifier).to eq('https://cocina.sul.stanford.edu/file/existing')
      end
    end

    context 'when there are multiple file sets and files' do
      let(:first_content_file_set) { create(:content_file_set, content:, position: 1, external_identifier: nil) }
      let(:second_content_file_set) { create(:content_file_set, content:, position: 2, external_identifier: nil) }

      before do
        create(:content_file, content_file_set: first_content_file_set, position: 1, external_identifier: nil,
                              content_file_binary: create(:content_file_binary, content:, filepath: 'image1.tif'))
        create(:content_file, content_file_set: first_content_file_set, position: 2, external_identifier: nil,
                              content_file_binary: create(:content_file_binary, content:, filepath: 'image2.tif'))
        create(:content_file, content_file_set: second_content_file_set, position: 1, external_identifier: nil,
                              content_file_binary: create(:content_file_binary, content:, filepath: 'image3.tif'))
      end

      it 'mints a distinct external identifier for each file set and file' do
        call

        external_identifiers = [
          first_content_file_set.reload.external_identifier,
          second_content_file_set.reload.external_identifier,
          *first_content_file_set.content_files.map { |content_file| content_file.reload.external_identifier },
          *second_content_file_set.content_files.map { |content_file| content_file.reload.external_identifier }
        ]

        expect(external_identifiers.uniq.size).to eq(external_identifiers.size)
      end
    end
  end
end
