# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Contents::Populators::Media do
  subject(:structure) { described_class.structure(content:, cocina_object:) }

  let(:content) { create(:content, druid: 'druid:bc123df4567') }
  let(:cocina_object) do
    build(:dro_with_metadata, id: content.druid).new(access: { view: 'world', download: 'world' })
  end

  def create_binary(filepath, mime_type, size: 100)
    create(:content_file_binary, content:, filepath:, mime_type:, size:)
  end

  # @return [Array<Array>] the type, label, and filepaths of each file set, in order
  def file_sets
    content.content_file_sets.map do |content_file_set|
      [content_file_set.file_set_type, content_file_set.label, content_file_set.content_files.map(&:filepath)]
    end
  end

  def content_file(label)
    content.content_files.find_by(label:)
  end

  def preserved_only
    { preserve: true, shelve: false, publish: false }
  end

  def published
    { preserve: true, shelve: true, publish: true }
  end

  describe '.disqualifying_reasons' do
    subject(:reasons) { described_class.disqualifying_reasons(content:, cocina_object:) }

    context 'when there is an audio file' do
      before { create_binary('audio.wav', 'audio/x-wav') }

      it 'has no reasons' do
        expect(reasons).to eq([])
      end
    end

    context 'when the object is dark' do
      let(:cocina_object) do
        build(:dro_with_metadata, id: content.druid).new(access: { view: 'dark', download: 'none' })
      end

      before { create_binary('video.mov', 'video/quicktime') }

      it 'has no reasons' do
        expect(reasons).to eq([])
      end
    end

    context 'when there are no audio or video files' do
      before { create_binary('image.tif', 'image/tiff') }

      it 'is disqualified' do
        expect(reasons).to eq([:no_media])
      end
    end

    context 'when there are hierarchical filepaths' do
      before { create_binary('folder/video.mp4', 'video/mp4') }

      it 'is disqualified' do
        expect(reasons).to eq([:hierarchical_filepaths])
      end
    end
  end

  describe '.structure in simple mode' do
    context 'when a video has captions' do
      before do
        create_binary('video.vtt', 'text/vtt')
        create_binary('video.mp4', 'video/mp4')
      end

      it 'groups them into a video file set' do
        structure

        expect(file_sets).to eq([['video', 'Video file 1', %w[video.mp4 video.vtt]]])
      end

      it 'preserves the video only and publishes the captions' do
        structure

        expect(content_file('video.mp4')).to have_attributes(**preserved_only, use: nil,
                                                                               view: 'world', download: 'world')
        expect(content_file('video.vtt')).to have_attributes(**published, use: 'caption')
      end
    end

    context 'when there are preservation and access copies with the same basename' do
      before do
        create_binary('video.mov', 'video/quicktime', size: 1000)
        create_binary('video.mp4', 'video/mp4', size: 10)
        create_binary('audio.wav', 'audio/wav', size: 1000)
        create_binary('audio.m4a', 'audio/mp4', size: 10)
      end

      it 'groups each into a single file set, in filepath order, preserving all of them' do
        structure

        expect(file_sets).to eq([['audio', 'Audio file 1', %w[audio.m4a audio.wav]],
                                 ['video', 'Video file 1', %w[video.mov video.mp4]]])
        expect(content.content_files).to all(have_attributes(**preserved_only))
      end
    end

    context 'when there are multiple audio and video files' do
      before do
        create_binary('b.mp3', 'audio/mpeg')
        create_binary('a.mkv', 'video/x-matroska')
        create_binary('c.mp4', 'video/mp4')
        create_binary('d.m4a', 'audio/mp4')
      end

      it 'sorts them together, numbering videos and audio separately' do
        structure

        expect(file_sets).to eq([['video', 'Video file 1', ['a.mkv']], ['audio', 'Audio file 1', ['b.mp3']],
                                 ['video', 'Video file 2', ['c.mp4']], ['audio', 'Audio file 2', ['d.m4a']]])
      end
    end

    context 'when there are images and other files' do
      before do
        create_binary('aaa_notes.txt', 'text/plain')
        create_binary('captions.vtt', 'text/vtt')
        create_binary('cover.tif', 'image/tiff')
        create_binary('cover.jp2', 'image/jp2')
        create_binary('cover.png', 'image/png')
        create_binary('poster.jp2', 'image/jp2')
        create_binary('video.mp4', 'video/mp4')
      end

      it 'places the images after the videos, followed by the other files' do
        structure

        expect(file_sets).to eq([['video', 'Video file 1', ['video.mp4']],
                                 ['image', 'Image 1', %w[cover.jp2 cover.png]],
                                 ['image', 'Image 2', ['cover.tif']],
                                 ['image', 'Image 3', ['poster.jp2']],
                                 ['file', 'File 1', ['aaa_notes.txt']],
                                 ['file', 'File 2', ['captions.vtt']]])
      end

      it 'uses the attributes for the mime types of the images and other files' do
        structure

        expect(content_file('cover.tif')).to have_attributes(**preserved_only)
        expect(content_file('cover.jp2')).to have_attributes(preserve: false, shelve: true, publish: true)
        expect(content_file('captions.vtt')).to have_attributes(**preserved_only, use: nil)
      end
    end

    context 'when a filename has a script flag but there are no role flags' do
      before do
        create_binary('recording.mp4', 'video/mp4')
        create_binary('recording_script.pdf', 'application/pdf')
      end

      it 'places the script in a file file set' do
        structure

        expect(file_sets).to eq([['video', 'Video file 1', ['recording.mp4']],
                                 ['file', 'File 1', ['recording_script.pdf']]])
      end
    end

    context 'when the object is dark' do
      let(:cocina_object) do
        build(:dro_with_metadata, id: content.druid).new(access: { view: 'dark', download: 'none' })
      end

      before do
        create_binary('video.mp4', 'video/mp4')
        create_binary('video.vtt', 'text/vtt')
      end

      it 'preserves but does not publish the captions' do
        structure

        expect(content_file('video.vtt')).to have_attributes(**preserved_only, use: 'caption', view: 'dark')
      end
    end
  end

  describe '.structure in SMPL mode' do
    context 'when a track has a preservation master and an access copy' do
      before do
        create_binary('bb010dx6027_t02_pm.wav', 'audio/x-wav', size: 34_220_086)
        create_binary('bb010dx6027_t02_sl.m4a', 'audio/mp4', size: 7_817_727)
        create_binary('bb010dx6027_t01_pm.wav', 'audio/x-wav', size: 34_714_006)
        create_binary('bb010dx6027_t01_sl.m4a', 'audio/mp4', size: 7_929_411)
      end

      it 'groups the files for each track into an audio file set' do
        structure

        expect(file_sets).to eq([['audio', 'Audio file 1', %w[bb010dx6027_t01_pm.wav bb010dx6027_t01_sl.m4a]],
                                 ['audio', 'Audio file 2', %w[bb010dx6027_t02_pm.wav bb010dx6027_t02_sl.m4a]]])
      end

      it 'preserves the master and publishes the access copy' do
        structure

        expect(content_file('bb010dx6027_t01_pm.wav')).to have_attributes(**preserved_only)
        expect(content_file('bb010dx6027_t01_sl.m4a')).to have_attributes(**published)
      end
    end

    context 'when the recordings are sides with processed masters, captions, and thumbnails' do
      before do
        create_binary('bd106pj9424_a_pm.mov', 'video/quicktime', size: 5000)
        create_binary('bd106pj9424_a_sp_pm.mov', 'video/quicktime', size: 5000)
        create_binary('bd106pj9424_a_sh.mp4', 'video/mp4', size: 500)
        create_binary('bd106pj9424_a_sl.mp4', 'video/mp4', size: 50)
        create_binary('bd106pj9424_a_cap.vtt', 'text/vtt')
        create_binary('bd106pj9424_a_thumb.jp2', 'image/jp2')
        create_binary('bd106pj9424_b_pm.mov', 'video/quicktime', size: 5000)
      end

      it 'groups the files of each side into a video file set' do
        structure

        expect(file_sets).to eq(
          [['video', 'Video file 1', %w[bd106pj9424_a_cap.vtt bd106pj9424_a_pm.mov bd106pj9424_a_sh.mp4
                                        bd106pj9424_a_sl.mp4 bd106pj9424_a_sp_pm.mov bd106pj9424_a_thumb.jp2]],
           ['video', 'Video file 2', ['bd106pj9424_b_pm.mov']]]
        )
      end

      it 'publishes the smallest MP4, the captions, and the thumbnail' do
        structure

        expect(content_file('bd106pj9424_a_pm.mov')).to have_attributes(**preserved_only)
        expect(content_file('bd106pj9424_a_sp_pm.mov')).to have_attributes(**preserved_only)
        expect(content_file('bd106pj9424_a_sh.mp4')).to have_attributes(**preserved_only)
        expect(content_file('bd106pj9424_a_sl.mp4')).to have_attributes(**published)
        expect(content_file('bd106pj9424_a_cap.vtt')).to have_attributes(**published, use: 'caption')
        expect(content_file('bd106pj9424_a_thumb.jp2')).to have_attributes(preserve: false, shelve: true, publish: true)
      end
    end

    context 'when a recording has captions but no access copy' do
      before do
        create_binary('bd106pj9424_pm.wav', 'audio/wav')
        create_binary('bd106pj9424_cap.vtt', 'text/vtt')
      end

      it 'preserves but does not publish the captions' do
        structure

        expect(content_file('bd106pj9424_cap.vtt')).to have_attributes(**preserved_only, use: 'caption')
      end
    end

    context 'when there are scripts, images, and other files' do
      before do
        create_binary('vr175ab4759_a_pm.wav', 'audio/wav')
        create_binary('vr175ab4759_a_script.pdf', 'application/pdf')
        create_binary('vr175ab4759_b_pm.mov', 'video/quicktime')
        create_binary('vr175ab4759_b_script.txt', 'text/plain')
        create_binary('vr175ab4759_a_sl_techmd.xml', 'application/xml')
        create_binary('vr175ab4759_script.pdf', 'application/pdf')
        create_binary('vr175ab4759_1.tif', 'image/tiff')
        create_binary('vr175ab4759_2.tif', 'image/tiff')
        create_binary('vr175ab4759_3.png', 'image/png')
      end

      it 'places the images after the audio and video, followed by the transcripts and other files' do
        structure

        expect(file_sets).to eq([['audio', 'Audio file 1', ['vr175ab4759_a_pm.wav']],
                                 ['video', 'Video file 1', ['vr175ab4759_b_pm.mov']],
                                 ['image', 'Image of media (1 of 2)', ['vr175ab4759_1.tif']],
                                 ['image', 'Image of media (2 of 2)', ['vr175ab4759_2.tif']],
                                 ['file', 'File 1', ['vr175ab4759_3.png']],
                                 ['file', 'Audio file 1 transcript', ['vr175ab4759_a_script.pdf']],
                                 ['file', 'File 2', ['vr175ab4759_a_sl_techmd.xml']],
                                 ['file', 'Video file 1 transcript', ['vr175ab4759_b_script.txt']],
                                 ['file', 'File 3', ['vr175ab4759_script.pdf']]])
      end

      it 'marks the transcripts as transcriptions, but not the script without a recording' do
        structure

        expect(content_file('vr175ab4759_a_script.pdf')).to have_attributes(**published, use: 'transcription')
        expect(content_file('vr175ab4759_b_script.txt')).to have_attributes(**published, use: 'transcription')
        expect(content_file('vr175ab4759_script.pdf')).to have_attributes(use: nil)
      end
    end

    context 'when the object is dark' do
      let(:cocina_object) do
        build(:dro_with_metadata, id: content.druid).new(access: { view: 'dark', download: 'none' })
      end

      before do
        create_binary('bb010dx6027_t01_pm.wav', 'audio/x-wav')
        create_binary('bb010dx6027_t01_sl.m4a', 'audio/mp4')
        create_binary('bb010dx6027_t01_cap.vtt', 'text/vtt')
        create_binary('bb010dx6027_t01_script.pdf', 'application/pdf')
      end

      it 'preserves but does not publish any files' do
        structure

        expect(content.content_files).to all(have_attributes(**preserved_only, view: 'dark'))
      end
    end

    context 'when the structure would pass content type validation' do
      before do
        create_binary('bb010dx6027_t01_pm.wav', 'audio/x-wav', size: 1000)
        create_binary('bb010dx6027_t01_sh.m4a', 'audio/mp4', size: 100)
        create_binary('bb010dx6027_t01_sl.m4a', 'audio/mp4', size: 10)
        create_binary('bb010dx6027_t01_cap.vtt', 'text/vtt')
        create_binary('bb010dx6027_t01_thumb.jp2', 'image/jp2')
        create_binary('bb010dx6027_t01_script.pdf', 'application/pdf')
        create_binary('bb010dx6027_1.tif', 'image/tiff')
      end

      it 'has no validation errors or warnings' do
        structure

        expect(Contents::Validators::Media.call(content:, dark: false))
          .to have_attributes(errors: [], warnings: [])
      end
    end
  end

  describe 'content type validation in simple mode' do
    before do
      create_binary('video.mov', 'video/quicktime')
      create_binary('video.mp4', 'video/mp4')
      create_binary('video.vtt', 'text/vtt')
      create_binary('audio.m4a', 'audio/mp4')
      create_binary('audio.vtt', 'text/vtt')
      create_binary('cover.tif', 'image/tiff')
      create_binary('cover.jp2', 'image/jp2')
    end

    it 'has no validation errors or warnings' do
      structure

      expect(Contents::Validators::Media.call(content:, dark: false)).to have_attributes(errors: [], warnings: [])
    end
  end

  describe '.append' do
    subject(:append) { described_class.append(content:, cocina_object:) }

    def create_existing_file_set(file_set_type:, label:, files:)
      position = content.content_file_sets.count + 1
      content_file_set = create(:content_file_set, content:, file_set_type:, label:, position:)
      files.each.with_index(1) do |(filepath, mime_type, attributes), file_position|
        create(:content_file, content_file_set:, content_file_binary: create_binary(filepath, mime_type),
                              label: filepath, position: file_position, **attributes)
      end
    end

    context 'when an access copy and captions are added to an SMPL recording' do
      before do
        create_existing_file_set(file_set_type: 'audio', label: 'Audio file 1',
                                 files: [['bb010dx6027_t01_pm.wav', 'audio/x-wav', preserved_only]])
        create_binary('bb010dx6027_t01_sl.m4a', 'audio/mp4')
        create_binary('bb010dx6027_t01_cap.vtt', 'text/vtt')
      end

      it 'adds them to the existing file set, publishing them' do
        append

        expect(file_sets).to eq([['audio', 'Audio file 1', %w[bb010dx6027_t01_pm.wav bb010dx6027_t01_cap.vtt
                                                              bb010dx6027_t01_sl.m4a]]])
        expect(content_file('bb010dx6027_t01_sl.m4a')).to have_attributes(**published)
        expect(content_file('bb010dx6027_t01_cap.vtt')).to have_attributes(**published, use: 'caption')
      end
    end

    context 'when a smaller access copy is added to an SMPL recording' do
      before do
        create_existing_file_set(file_set_type: 'video', label: 'Video file 1',
                                 files: [['bd106pj9424_pm.mov', 'video/quicktime', preserved_only],
                                         ['bd106pj9424_sh.mp4', 'video/mp4', published],
                                         ['bd106pj9424_cap.vtt', 'text/vtt', published.merge(use: 'caption')]])
        create_binary('bd106pj9424_sl.mp4', 'video/mp4', size: 10)
      end

      it 'publishes the smaller access copy instead of the existing one' do
        append

        expect(content_file('bd106pj9424_sl.mp4')).to have_attributes(**published)
        expect(content_file('bd106pj9424_sh.mp4')).to have_attributes(**preserved_only)
        expect(content_file('bd106pj9424_cap.vtt')).to have_attributes(**published, use: 'caption')
      end
    end

    context 'when a script is added for an SMPL recording' do
      before do
        create_existing_file_set(file_set_type: 'audio', label: 'Interview',
                                 files: [['bb010dx6027_t01_pm.wav', 'audio/x-wav', preserved_only]])
        create_existing_file_set(file_set_type: 'file', label: 'File 1',
                                 files: [['bb010dx6027_techmd.xml', 'application/xml', preserved_only]])
        create_binary('bb010dx6027_t01_script.pdf', 'application/pdf')
        create_binary('bb010dx6027_notes.pdf', 'application/pdf')
      end

      it 'creates transcript and file file sets at the end, labeled after the recording and continuing the numbering' do
        append

        expect(file_sets.map(&:second)).to eq(['Interview', 'File 1', 'File 2', 'Interview transcript'])
      end
    end

    context 'when a simple-mode access copy, captions, and a JP2 are added' do
      before do
        create_existing_file_set(file_set_type: 'video', label: 'Video file 1',
                                 files: [['video.mov', 'video/quicktime', preserved_only]])
        create_existing_file_set(file_set_type: 'image', label: 'Image 1',
                                 files: [['cover.tif', 'image/tiff', preserved_only]])
        create_binary('video.mp4', 'video/mp4')
        create_binary('video.vtt', 'text/vtt')
        create_binary('cover.jp2', 'image/jp2')
        create_binary('other.mp4', 'video/mp4')
      end

      it 'adds them to the existing file sets, and creates a file set at the end for the other video' do
        append

        expect(file_sets).to eq([['video', 'Video file 1', %w[video.mov video.mp4 video.vtt]],
                                 ['image', 'Image 1', %w[cover.tif cover.jp2]],
                                 ['video', 'Video file 2', ['other.mp4']]])
      end
    end

    context 'when an image is added to an SMPL item' do
      before do
        create_existing_file_set(file_set_type: 'audio', label: 'Audio file 1',
                                 files: [['bb010dx6027_t01_pm.wav', 'audio/x-wav', preserved_only]])
        create_existing_file_set(file_set_type: 'image', label: 'Image of media (1 of 1)',
                                 files: [['bb010dx6027_1.tif', 'image/tiff', preserved_only]])
        create_binary('bb010dx6027_2.tif', 'image/tiff')
      end

      it 'continues the image numbering' do
        append

        expect(file_sets.map(&:second)).to eq(['Audio file 1', 'Image of media (1 of 1)', 'Image of media (2 of 2)'])
      end
    end
  end
end
