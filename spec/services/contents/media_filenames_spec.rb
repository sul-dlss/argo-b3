# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Contents::MediaFilenames do
  subject(:media_filenames) { described_class.new(media_content_file_binaries:) }

  let(:media_content_file_binaries) { [binary('bb010dx6027_t01_pm.wav'), binary('bb010dx6027_ab_pm.wav')] }

  def binary(filepath)
    create(:content_file_binary, filepath:)
  end

  describe '#stem_for and #language_tag_for' do
    it 'removes the language of a caption from its stem' do
      expect(media_filenames.stem_for(binary('bb010dx6027_t01_es_cap.vtt'))).to eq('bb010dx6027_t01')
      expect(media_filenames.language_tag_for(binary('bb010dx6027_t01_es_cap.vtt'))).to eq('es')
    end

    it 'keeps a flag that is part of a recording' do
      expect(media_filenames.stem_for(binary('bb010dx6027_ab_cap.vtt'))).to eq('bb010dx6027_ab')
      expect(media_filenames.language_tag_for(binary('bb010dx6027_ab_cap.vtt'))).to be_nil
    end

    it 'does not take a track or a file flag for a language' do
      expect(media_filenames.language_tag_for(binary('bb010dx6027_t01_cap.vtt'))).to be_nil
      expect(media_filenames.language_tag_for(binary('bb010dx6027_t01_sl_cap.vtt'))).to be_nil
    end

    it 'does not take a flag after the caption flag for a language' do
      expect(media_filenames.language_tag_for(binary('bb010dx6027_t01_cap_en.vtt'))).to be_nil
    end

    context 'when not in SMPL mode' do
      let(:media_content_file_binaries) { [binary('video.mov')] }

      it 'has no language' do
        expect(media_filenames.stem_for(binary('video_en_cap.vtt'))).to eq('video_en_cap')
        expect(media_filenames.language_tag_for(binary('video_en_cap.vtt'))).to be_nil
      end
    end
  end
end
