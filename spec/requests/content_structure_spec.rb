# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Content structure' do
  let(:druid) { 'druid:bc123df4567' }
  let(:cocina_object) { build(:dro_with_metadata, id: druid) }
  let(:content) { create(:content, druid:, lock: cocina_object.lock) }
  let(:content_token) { Rails.application.message_verifier(:argo).generate(content.id, purpose: 'contents') }

  before do
    allow(Sdr::Repository).to receive(:find).and_return(cocina_object)
    sign_in(create(:user))
  end

  describe 'updating with an unknown populator' do
    it 'returns bad request' do
      patch content_structure_path(content_id: content_token),
            params: { commit: ContentStructureController::STRUCTURE_VALUE, populator: 'Base' }

      expect(response).to have_http_status(:bad_request)
    end
  end
end
