# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Contents::UnsavedChanges do
  subject(:unsaved_content_changes) { described_class.call(content:, cocina_object:) }

  let(:druid) { 'druid:bc123df4567' }
  let(:cocina_object) do
    build(:dro_with_metadata, id: druid).new(
      access: { view: 'world', download: 'world' },
      structural: {
        contains: [
          cocina_file_set(label: 'Page 1', filenames: %w[page1.tif page1.txt]),
          cocina_file_set(label: 'Page 2', filenames: %w[page2.tif])
        ]
      }
    )
  end
  let(:content) { Contents::Builder.call(cocina_object:, immutable: false) }
  let(:first_file_set) { content.content_file_sets.first }
  let(:first_file) { first_file_set.content_files.first }

  def cocina_file_set(label:, filenames:)
    {
      type: Cocina::Models::FileSetType.page,
      externalIdentifier: "#{druid}_#{label.parameterize}",
      label:,
      version: 1,
      structural: { contains: filenames.map { |filename| cocina_file(filename:) } }
    }
  end

  def cocina_file(filename:)
    {
      type: Cocina::Models::ObjectType.file,
      externalIdentifier: "#{druid}_#{filename}",
      label: filename,
      filename:,
      version: 1,
      hasMimeType: 'image/tiff',
      hasMessageDigests: [{ type: 'md5', digest: '1a2b3c' }],
      access: { view: 'world', download: 'world' },
      administrative: { publish: true, sdrPreserve: true, shelve: true }
    }
  end

  context 'when there is no content' do
    let(:content) { nil }

    it 'returns false' do
      expect(unsaved_content_changes).to be false
    end
  end

  context 'when the content is unchanged' do
    it 'returns false' do
      expect(unsaved_content_changes).to be false
    end
  end

  context 'when the content has been staged but is otherwise unchanged' do
    before { content.content_file_binaries.update_all(file_location: 'stage') } # rubocop:disable Rails/SkipsModelValidations

    it 'returns false' do
      expect(unsaved_content_changes).to be false
    end
  end

  context 'when a binary has not been staged' do
    before { create(:content_file_binary, content:, file_location: 'attached', filepath: 'new.tif') }

    it 'returns true' do
      expect(unsaved_content_changes).to be true
    end
  end

  context 'when a resource attribute changed' do
    before { first_file_set.update!(label: 'Cover') }

    it 'returns true' do
      expect(unsaved_content_changes).to be true
    end
  end

  context 'when the resources are reordered' do
    before do
      first_file_set.update!(position: 3)
    end

    it 'returns true' do
      expect(unsaved_content_changes).to be true
    end
  end

  context 'when a resource is removed' do
    before { content.content_file_sets.last.destroy! }

    it 'returns true' do
      expect(unsaved_content_changes).to be true
    end
  end

  context 'when a file is reordered' do
    before { first_file.update!(position: 3) }

    it 'returns true' do
      expect(unsaved_content_changes).to be true
    end
  end

  context 'when a file is removed' do
    before { first_file.destroy! }

    it 'returns true' do
      expect(unsaved_content_changes).to be true
    end
  end

  {
    label: 'Cover image',
    use: 'transcription',
    view: 'stanford',
    download: 'none',
    language_tag: 'en',
    corrected_for_accessibility: true,
    sdr_generated_text: true,
    publish: false,
    preserve: false,
    shelve: false
  }.each do |attribute, value|
    context "when a file's #{attribute} changed" do
      before { first_file.update_columns(attribute => value) } # rubocop:disable Rails/SkipsModelValidations

      it 'returns true' do
        expect(unsaved_content_changes).to be true
      end
    end
  end

  context "when a file's location changed" do
    before { first_file.update_columns(view: 'location-based', download: 'location-based', location: 'spec') } # rubocop:disable Rails/SkipsModelValidations

    it 'returns true' do
      expect(unsaved_content_changes).to be true
    end
  end

  context "when a file's mime type changed" do
    before { first_file.content_file_binary.update!(mime_type: 'image/jp2') }

    it 'returns true' do
      expect(unsaved_content_changes).to be true
    end
  end
end
