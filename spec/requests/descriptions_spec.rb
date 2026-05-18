# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Editing description' do
  let(:druid) { 'druid:bc123df4567' }
  let(:cocina_object) { build(:dro_with_metadata, id: druid) }
  let(:admin_user) { create(:user, :admin) }
  let(:non_admin_user) { create(:user) }

  before do
    allow(Sdr::Repository).to receive(:find).with(druid:).and_return(cocina_object)
  end

  describe 'GET /objects/:druid/description/edit' do
    context 'when the user is an admin' do
      before { sign_in admin_user }

      it 'renders the edit form' do
        get edit_object_description_path(object_druid: druid)

        expect(response).to have_http_status(:ok)
      end
    end

    context 'when the user is not an admin' do
      before { sign_in non_admin_user }

      it 'redirects with an authorization error' do
        get edit_object_description_path(object_druid: druid)

        expect(response).to redirect_to(root_path)
      end
    end
  end

  describe 'PATCH /objects/:druid/description' do
    let(:description_params) do
      {
        description: {
          title: [{ value: 'Updated Title', type: '' }],
          note: [{ value: 'An abstract.', type: 'abstract' }],
          language: [{ code: 'eng', value: 'English' }],
          contributor: [{ name_value: 'Smith, Jane', type: 'person', primary: '1' }],
          subject: [{ value: 'History', type: 'topic', source_code: 'lcsh' }],
          form: [{ value: '1 score (77 leaves)', type: 'extent' }],
          event: [{ type: 'publication', date_value: '1978', place_value: 'New York' }],
          related_resource: [{ title_value: 'Finding Aid', type: 'described by', url: 'https://example.com/fa' }],
          access: {
            physical_location: [{ value: 'PC0139', type: 'shelf locator' }],
            access_contact: [{ value: 'spec@stanford.edu', type: 'email' }]
          }
        }
      }
    end

    context 'when the user is an admin' do
      before do
        sign_in admin_user
        allow(Sdr::VersionService).to receive_messages(open?: true, closeable?: true)
        allow(Sdr::VersionService).to receive(:close)
        allow(Sdr::Repository).to receive(:update)
      end

      it 'updates the description and redirects to the object page' do
        patch object_description_path(object_druid: druid), params: description_params

        expect(Sdr::Repository).to have_received(:update) do |args|
          updated_description = args[:cocina_object].description
          expect(updated_description.title.first.value).to eq('Updated Title')
          expect(updated_description.note.first.value).to eq('An abstract.')
          expect(updated_description.language.first.code).to eq('eng')
        end
        expect(response).to redirect_to(object_path(druid:))
      end

      it 'closes the version after saving' do
        patch object_description_path(object_druid: druid), params: description_params

        expect(Sdr::VersionService).to have_received(:close).with(druid:)
      end

      it 'opens a version when the object version is closed' do
        allow(Sdr::VersionService).to receive(:open?).and_return(false)
        allow(Sdr::VersionService).to receive(:open)

        patch object_description_path(object_druid: druid), params: description_params

        expect(Sdr::VersionService).to have_received(:open).with(
          druid:,
          description: 'Descriptive metadata edited via web form',
          opening_user_name: admin_user.sunetid
        )
      end

      it 'does not close the version if it is not closeable' do
        allow(Sdr::VersionService).to receive(:closeable?).and_return(false)

        patch object_description_path(object_druid: druid), params: description_params

        expect(Sdr::VersionService).not_to have_received(:close)
      end

      it 're-renders the form when validation fails' do
        allow(CocinaSupport).to receive(:validate).and_return(Dry::Monads::Failure('title is required'))

        patch object_description_path(object_druid: druid), params: description_params

        expect(response).to have_http_status(:unprocessable_content)
        expect(Sdr::Repository).not_to have_received(:update)
      end
    end

    context 'when the user is not an admin' do
      before { sign_in non_admin_user }

      it 'redirects with an authorization error' do
        patch object_description_path(object_druid: druid), params: description_params

        expect(response).to redirect_to(root_path)
      end
    end
  end
end
