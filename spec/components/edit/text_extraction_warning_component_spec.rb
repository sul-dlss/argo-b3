# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Edit::TextExtractionWarningComponent, type: :component do
  let(:ocr_warning) do
    'that were generated outside SDR or that have been corrected to comply with accessibility standards.'
  end
  let(:speech_to_text_warning) do
    'Do not auto-generate captions/transcripts for media files that do not contain any speech or lyrics.'
  end

  context 'when warning about OCR' do
    it 'renders the OCR warning only' do
      render_inline(described_class.new(ocr: true, speech_to_text: false))

      expect(page).to have_css('.alert-info', text: ocr_warning)
      expect(page).to have_no_text(speech_to_text_warning)
    end
  end

  context 'when warning about speech to text' do
    it 'renders the captions warning only' do
      render_inline(described_class.new(ocr: false, speech_to_text: true))

      expect(page).to have_css('.alert-info', text: speech_to_text_warning)
      expect(page).to have_no_text(ocr_warning)
    end
  end

  context 'when warning about both' do
    it 'renders both warnings' do
      render_inline(described_class.new(ocr: true, speech_to_text: true))

      expect(page).to have_text(ocr_warning)
      expect(page).to have_text(speech_to_text_warning)
    end
  end
end
