# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Text extraction bulk action' do
  let(:rendered_page) { Capybara.string(response.body) }
  let(:speech_to_text_warning) do
    'Do not auto-generate captions/transcripts for media files that do not contain any speech or lyrics.'
  end

  before { sign_in create(:user) }

  describe 'new' do
    it 'warns against speech to text for media without speech' do
      get new_bulk_actions_text_extraction_path

      expect(rendered_page).to have_css('.alert-info', text: speech_to_text_warning)
    end

    context 'when speech to text is not enabled' do
      before { allow(Settings.features).to receive(:speech_to_text_workflow).and_return(false) }

      it 'does not warn against speech to text' do
        get new_bulk_actions_text_extraction_path

        expect(rendered_page).to have_no_text(speech_to_text_warning)
      end
    end
  end
end
