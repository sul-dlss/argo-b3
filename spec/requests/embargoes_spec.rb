# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Embargoes' do
  let(:druid) { 'druid:bc123df4567' }
  let(:user) { create(:user) }
  let(:release_date) { DateTime.parse('2040-06-15T19:00:00Z') }
  let(:cocina_object) do
    build(:dro_with_metadata, id: druid).new(
      access: {
        embargo: {
          releaseDate: release_date,
          view: 'world',
          download: 'world'
        }
      }
    )
  end

  before do
    create(:permission, :edit, workgroup: user.groups.first, target_druid: druid)
    allow(Sdr::Repository).to receive(:find).with(druid:).and_return(cocina_object)
    sign_in(user)
  end

  describe 'GET /objects/:object_druid/embargo/edit' do
    it 'renders the current embargo release date' do
      get edit_object_embargo_path(druid)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('Edit embargo release date')
      expect(response.body).to include('value="2040-06-15"')
    end
  end

  describe 'PATCH /objects/:object_druid/embargo' do
    before do
      allow(Sdr::Repository).to receive(:update)
      allow(Sdr::VersionService).to receive(:open?).with(druid:).and_return(true)
    end

    it 'updates the embargo release date' do
      patch object_embargo_path(druid), params: {
        embargo: { embargo_release_date: '2041-01-31' }
      }

      expect(response).to redirect_to(object_path(druid))
      expect(Sdr::Repository).to have_received(:update) do |args|
        expect(args[:cocina_object].access.embargo.releaseDate).to eq(DateTime.parse('2041-01-31'))
        expect(args[:cocina_object].access.embargo.view).to eq('world')
        expect(args[:cocina_object].access.embargo.download).to eq('world')
        expect(args[:user_name]).to eq(user.sunetid)
        expect(args[:description]).to eq('Updated embargo release date')
      end
    end

    it 'does not update when the release date is missing' do
      patch object_embargo_path(druid), params: {
        embargo: { embargo_release_date: '' }
      }

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.parsed_body.text).to include("can't be blank")
      expect(Sdr::Repository).not_to have_received(:update)
    end

    context 'when the object does not have an open version' do
      before do
        allow(Sdr::VersionService).to receive(:open?).with(druid:).and_return(false)
        allow(Sdr::VersionService).to receive(:openable?).with(druid:).and_return(true)
        allow(Sdr::VersionService).to receive(:open).with(
          druid:,
          description: 'Updated embargo release date',
          opening_user_name: user.sunetid
        ).and_return(cocina_object)
      end

      it 'opens a new version before updating' do
        patch object_embargo_path(druid), params: {
          embargo: { embargo_release_date: '2041-01-31' }
        }

        expect(response).to redirect_to(object_path(druid))
        expect(Sdr::VersionService).to have_received(:open).with(
          druid:,
          description: 'Updated embargo release date',
          opening_user_name: user.sunetid
        )
      end
    end
  end
end
