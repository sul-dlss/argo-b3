# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Contents::Validators::Media do
  subject(:result) { described_class.call(content:, dark:) }

  let(:content) { create(:content, druid: 'druid:bc123df4567') }
  let(:dark) { false }
  let(:missing_media_warning) do
    'No video or audio resource has exactly one MP4 (video) or M4A (audio) file, ' \
      'or an MP3, MOV, MKV, or WAV file.'
  end

  # @param [Array<Array>] files the filepath, mime type, and publish flag of each file
  def create_resource(file_set_type:, files:, label: '')
    position = content.content_file_sets.count + 1
    content_file_set = create(:content_file_set, content:, file_set_type:, label:, position:)
    files.each.with_index(1) do |(filepath, mime_type, publish), file_position|
      content_file_binary = create(:content_file_binary, content:, filepath:, mime_type:)
      create(:content_file, content_file_set:, content_file_binary:, position: file_position, label: filepath,
                            publish:, shelve: publish)
    end
  end

  context 'when the resources are valid' do
    before do
      create_resource(file_set_type: 'video', label: 'Video 1',
                      files: [['video.mp4', 'video/mp4', true], ['captions.vtt', 'text/vtt', true],
                              ['poster.jp2', 'image/jp2', true], ['transcript.txt', 'text/plain', true]])
      create_resource(file_set_type: 'audio', label: 'Audio 1', files: [['audio.m4a', 'audio/mp4', true]])
      create_resource(file_set_type: 'file', files: [['notes.pdf', 'application/pdf', true]])
      create_resource(file_set_type: 'image',
                      files: [['cover.jpg', 'image/jpeg', true], ['cover.tif', 'image/tiff', true],
                              ['cover.png', 'image/png', true], ['cover.jp2', 'image/jp2', true]])
      create_resource(file_set_type: 'document', files: [['unpublished.pdf', 'application/pdf', false]])
    end

    it 'has no errors or warnings' do
      expect(result).to have_attributes(errors: [], warnings: [])
    end
  end

  %w[video audio].each do |file_set_type|
    context "when a #{file_set_type} resource has more than one published MP4/M4A" do
      before do
        create_resource(file_set_type:, label: 'Media 1',
                        files: [['video.mp4', 'video/mp4', true], ['audio.m4a', 'audio/mp4', true]])
      end

      it 'has an error' do
        expect(result.errors).to eq(['Resource 1 (Media 1) has more than one published MP4/M4A file.'])
      end
    end

    context "when a #{file_set_type} resource has only one published MP4/M4A" do
      before do
        create_resource(file_set_type:,
                        files: [['video.mp4', 'video/mp4', true], ['audio.m4a', 'audio/mp4', false]])
      end

      it 'has no errors' do
        expect(result.errors).to eq([])
      end
    end

    context "when a #{file_set_type} resource publishes unsupported files" do
      before do
        create_resource(file_set_type:, label: 'Media 1',
                        files: [['video.mp4', 'video/mp4', true], ['source.wav', 'audio/wav', true],
                                ['unknown.dat', nil, true], ['notes.pdf', 'application/pdf', false]])
      end

      it 'has an error listing only the unsupported published files' do
        expect(result.errors).to eq([
                                      'Resource 1 (Media 1) has published files that are not ' \
                                      'MP4/M4A, VTT, JP2, or TXT: ' \
                                      'source.wav, unknown.dat.'
                                    ])
      end
    end
  end

  context 'when another resource type publishes non-image files' do
    before do
      create_resource(file_set_type: 'object', label: 'Object 1', files: [['notes.pdf', 'application/pdf', true]])
    end

    it 'has an error' do
      expect(result.errors).to eq([
                                    'Resource 1 (Object 1) has published files other than JPEG, TIFF, PNG, or JP2 ' \
                                    'but is not a video, audio, or file resource.'
                                  ])
    end
  end

  context 'when an invalid resource has a blank label' do
    before do
      create_resource(file_set_type: 'image', files: [['notes.pdf', 'application/pdf', true]])
    end

    it 'names the resource without a label' do
      expect(result.errors).to eq([
                                    'Resource 1 has published files other than JPEG, TIFF, PNG, or JP2 ' \
                                    'but is not a video, audio, or file resource.'
                                  ])
    end
  end

  context 'when dark' do
    let(:dark) { true }

    before do
      create_resource(file_set_type: 'video', label: 'Video 1',
                      files: [['video.mp4', 'video/mp4', true], ['video2.mp4', 'video/mp4', true],
                              ['notes.pdf', 'application/pdf', true], ['source.mov', 'video/quicktime', false]])
      create_resource(file_set_type: 'object', label: 'Object 1', files: [['data.zip', 'application/zip', true]])
    end

    it 'has warnings instead of errors for every violation' do
      expect(result).to have_attributes(
        errors: [],
        warnings: ['Resource 1 (Video 1) has more than one published MP4/M4A file.',
                   'Resource 1 (Video 1) has published files that are not MP4/M4A, VTT, JP2, or TXT: notes.pdf.',
                   'Resource 2 (Object 1) has published files other than JPEG, TIFF, PNG, or JP2 ' \
                   'but is not a video, audio, or file resource.']
      )
    end
  end

  [['video', 'video/mp4', 'video.mp4'],
   ['audio', 'audio/mp4', 'audio.m4a']].each do |file_set_type, mime_type, filepath|
    context "when a #{file_set_type} resource has exactly one matching media file" do
      before { create_resource(file_set_type:, files: [[filepath, mime_type, true]]) }

      it 'has no warnings' do
        expect(result.warnings).to eq([])
      end
    end

    context "when a #{file_set_type} resource has only unpublished MP4/M4A files" do
      before { create_resource(file_set_type:, files: [[filepath, mime_type, false]]) }

      it 'has no errors or warnings' do
        expect(result).to have_attributes(errors: [], warnings: [])
      end
    end

    context "when a #{file_set_type} resource has multiple matching media files" do
      before do
        create_resource(file_set_type:, files: [[filepath, mime_type, true], ["other_#{filepath}", mime_type, false]])
      end

      it 'also warns that there is no suitable media resource' do
        expect(result.warnings).to eq([missing_media_warning])
      end
    end
  end

  [['audio', 'video/mp4', 'video.mp4'],
   ['video', 'audio/mp4', 'audio.m4a']].each do |file_set_type, mime_type, filepath|
    context "when a #{file_set_type} resource has the wrong media type" do
      before { create_resource(file_set_type:, files: [[filepath, mime_type, true]]) }

      it 'warns that there is no suitable media resource' do
        expect(result.warnings).to eq([missing_media_warning])
      end
    end
  end

  media_file_set_types = %w[video audio]
  [['source.mp3', 'audio/mpeg'], ['source.mov', 'video/quicktime'], ['source.mkv', 'video/x-matroska'],
   ['source.wav', 'audio/wav'], ['source.wav', 'audio/x-wav']].each do |filepath, mime_type|
    media_file_set_types.each do |file_set_type|
      context "when a #{file_set_type} resource has an unpublished #{mime_type} source file" do
        before { create_resource(file_set_type:, files: [[filepath, mime_type, false]]) }

        it 'has no errors or warnings' do
          expect(result).to have_attributes(errors: [], warnings: [])
        end
      end
    end
  end

  context 'when suitable media files are only in file resources' do
    before do
      create_resource(file_set_type: 'file',
                      files: [['video.mp4', 'video/mp4', true], ['source.wav', 'audio/wav', false]])
      create_resource(file_set_type: 'audio', files: [['captions.vtt', 'text/vtt', true]])
    end

    it 'has a warning but no errors' do
      expect(result).to have_attributes(errors: [], warnings: [missing_media_warning])
    end
  end

  context 'when there are no resources' do
    it 'has a warning' do
      expect(result.warnings).to eq([missing_media_warning])
    end
  end
end
