# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Republish object' do
  let(:druid) { 'druid:bc123df4567' }
  let(:object_type) { 'item' }
  let(:solr_doc) do
    {
      Search::Fields::ID => druid,
      Search::Fields::OBJECT_TYPES => [object_type]
    }
  end

  before do
    allow(Sdr::Repository).to receive(:find_solr).with(druid:).and_return(solr_doc)
  end

  describe 'POST /objects/:druid/republish' do
    context 'when unauthenticated' do
      it 'redirects to login' do
        post republish_object_path(druid)

        expect(response).to redirect_to(login_path)
      end
    end

    context 'when authenticated without update permission' do
      before { sign_in(create(:user, :reader)) }

      it 'denies access' do
        post republish_object_path(druid)

        expect(response).to redirect_to(root_path)
        expect(flash[:warning]).to be_present
      end
    end

    context 'when authenticated with update permission' do
      let(:user) { create(:user, :reader) }

      before do
        create(:permission, :edit, workgroup: user.groups.first, target_druid: druid)
        sign_in(user)
      end

      context 'when the object has never been published' do
        before { allow(Sdr::WorkflowService).to receive(:published?).with(druid:).and_return(false) }

        it 'renders a 404 without publishing' do
          allow(Sdr::Repository).to receive(:publish)

          post republish_object_path(druid)

          expect(response).to have_http_status(:not_found)
          expect(Sdr::Repository).not_to have_received(:publish)
        end
      end

      context 'when the object is an agreement' do
        let(:object_type) { 'agreement' }

        it 'renders a 404 without checking whether it was previously published' do
          allow(Sdr::WorkflowService).to receive(:published?)

          post republish_object_path(druid)

          expect(response).to have_http_status(:not_found)
          expect(Sdr::WorkflowService).not_to have_received(:published?)
        end
      end

      context 'when the object is an APO' do
        let(:object_type) { 'APO' }

        it 'renders a 404 without checking whether it was previously published' do
          allow(Sdr::WorkflowService).to receive(:published?)

          post republish_object_path(druid)

          expect(response).to have_http_status(:not_found)
          expect(Sdr::WorkflowService).not_to have_received(:published?)
        end
      end

      context 'when the object has previously been published' do
        before do
          allow(Sdr::WorkflowService).to receive(:published?).with(druid:).and_return(true)
          allow(Sdr::Repository).to receive(:publish).with(druid:)
        end

        it 'publishes the object and redirects with a toast' do
          post republish_object_path(druid)

          expect(Sdr::Repository).to have_received(:publish).with(druid:)
          expect(response).to redirect_to(object_path(druid))
          expect(flash[:toast]).to eq('Republishing started')
        end
      end
    end
  end
end
