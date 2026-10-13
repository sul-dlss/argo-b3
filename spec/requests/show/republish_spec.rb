# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Republish object' do
  let(:druid) { 'druid:bc123df4567' }
  let(:solr_doc) do
    {
      Search::Fields::ID => druid,
      Search::Fields::OBJECT_TYPES => ['item']
    }
  end
  let(:user) { create(:user, :reader) }

  before do
    allow(Sdr::Repository).to receive(:find_solr).with(druid:).and_return(solr_doc)

    create(:permission, :edit, workgroup: user.groups.first, target_druid: druid)
    sign_in(user)
  end

  describe 'POST /objects/:druid/republish' do
    context 'when the object has never been published' do
      before do
        allow(Sdr::WorkflowService).to receive(:published?).with(druid:).and_return(false)
        allow(Sdr::Repository).to receive(:publish)
      end

      it 'does not publish and shows a warning' do
        post republish_object_path(druid)

        expect(Sdr::Repository).not_to have_received(:publish)
        expect(response).to redirect_to(object_path(druid))
        expect(flash[:warning]).to eq('Republish is not possible')
      end
    end

    context 'when the object has previously been published' do
      before do
        allow(Sdr::WorkflowService).to receive(:published?).with(druid:).and_return(true)
        allow(Sdr::Repository).to receive(:publish).with(druid:, lane_id: 'low')
      end

      it 'publishes and shows a toast' do
        post republish_object_path(druid)

        expect(Sdr::Repository).to have_received(:publish).with(druid:, lane_id: 'low')
        expect(response).to redirect_to(object_path(druid))
        expect(flash[:toast]).to eq('Republishing started')
      end

      context 'when a Turbo request' do
        it 'publishes, shows the toast, and refreshes the page with a turbo stream' do
          post republish_object_path(druid), headers: { 'Accept' => 'text/vnd.turbo-stream.html, text/html' }

          expect(Sdr::Repository).to have_received(:publish).with(druid:, lane_id: 'low')
          expect(response.media_type).to eq('text/vnd.turbo-stream.html')
          expect(response.body).to include('turbo-stream action="append" target="toast-container"')
          expect(response.body).to include('Republishing started')
          expect(response.body).to include('turbo-stream action="refresh"')
          expect(flash[:toast]).to be_nil
        end
      end
    end
  end
end
