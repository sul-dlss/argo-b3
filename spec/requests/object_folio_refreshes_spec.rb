# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Refresh from FOLIO' do
  let(:user) { create(:user, :reader) }
  let(:druid) { 'druid:bc123df4567' }
  let(:cocina_object) do
    build(:dro_with_metadata, id: druid, title: 'My item', version: 2, folio_instance_hrids: ['a123'])
  end
  # A closed version: Deposited.
  let(:version_service) do
    version_service_double(open?: false, openable?: true, closeable?: false, version: 2, open: nil)
  end
  # The version as DepositDraftService finds it, once opened.
  let(:deposit_version_service) { version_service_double(version: 3) }
  let(:refreshed_cocina_object) { cocina_object.new(version: 3, lock: 'refreshed-lock') }
  let(:object_client) do
    instance_double(Dor::Services::Client::Object, refresh_descriptive_metadata_from_ils: true)
  end
  let(:rendered_page) { Capybara.string(response.body) }

  before do
    allow(Sdr::Repository).to receive(:find).and_return(cocina_object, refreshed_cocina_object)
    allow(Sdr::Repository).to receive(:accession)
    allow(Sdr::VersionService).to receive(:new).and_return(version_service, deposit_version_service)
    allow(Dor::Services::Client).to receive(:object).with(druid).and_return(object_client)
    allow(FolioClient).to receive(:fetch_instance_info).and_return({ 'title' => 'Paying for college' })
    sign_in(user)
  end

  describe 'new' do
    context 'when the user can edit a deposited item' do
      before { create(:permission, :edit, workgroup: user.groups.first, target_druid: druid) }

      it 'shows the FOLIO record, the default version description, and the buttons' do
        get "/objects/#{druid}/folio_refresh/new"

        expect(response).to have_http_status(:ok)
        expect(rendered_page).to have_css('h1', text: 'Refresh from FOLIO')
        expect(rendered_page).to have_text('My item')
        expect(rendered_page).to have_css('dt', exact_text: 'FOLIO Instance HRID')
        expect(rendered_page).to have_css('dd', text: 'a123')
        expect(rendered_page).to have_css('dt', exact_text: 'FOLIO title statement')
        expect(rendered_page).to have_css('dd', text: 'Paying for college')
        expect(rendered_page).to have_field('Version description', with: 'Refresh from FOLIO')
        expect(rendered_page).to have_link('Cancel', href: "/objects/#{druid}")
        expect(rendered_page).to have_button('Refresh from FOLIO and save as draft', disabled: false)
        expect(rendered_page).to have_button('Refresh from FOLIO and deposit', disabled: false)
        expect(FolioClient).to have_received(:fetch_instance_info).with(hrid: 'a123')
      end
    end

    context 'when the item has a Draft' do
      let(:version_service) { version_service_double(version: 2, version_description: 'Fixing the title') }

      before { create(:permission, :edit, workgroup: user.groups.first, target_druid: druid) }

      it "prefills the Draft's version description" do
        get "/objects/#{druid}/folio_refresh/new"

        expect(rendered_page).to have_field('Version description', with: 'Fixing the title')
      end
    end

    context 'when the Draft has unsaved changes to its files' do
      let(:version_service) { version_service_double(version: 2, version_description: 'Fixing the title') }

      before do
        create(:permission, :edit, workgroup: user.groups.first, target_druid: druid)
        content = create(:content, :mutable, druid:, lock: cocina_object.lock)
        # A file that has not been staged is an unsaved change.
        create(:content_file_binary, content:, file_location: 'attached')
      end

      it 'offers only saving as a draft, with the reason' do
        get "/objects/#{druid}/folio_refresh/new"

        expect(rendered_page).to have_button('Refresh from FOLIO and save as draft')
        expect(rendered_page).to have_no_button('Refresh from FOLIO and deposit')
        expect(rendered_page).to have_text('Files have unsaved changes. Deposit from "Edit files and structure".')
      end
    end

    context 'when the FOLIO record cannot be retrieved' do
      before do
        create(:permission, :edit, workgroup: user.groups.first, target_druid: druid)
        allow(FolioClient).to receive(:fetch_instance_info).and_raise(FolioClient::ServiceUnavailable, 'Folio is down')
      end

      it 'disables the buttons, with the reason' do
        get "/objects/#{druid}/folio_refresh/new"

        expect(response).to have_http_status(:ok)
        expect(rendered_page).to have_css('dd', text: 'a123')
        expect(rendered_page).to have_no_css('dt', text: 'FOLIO title statement')
        expect(rendered_page).to have_button('Refresh from FOLIO and save as draft', disabled: true)
        expect(rendered_page).to have_button('Refresh from FOLIO and deposit', disabled: true)
        expect(rendered_page).to have_text("The FOLIO record couldn't be retrieved. Try again, or contact SDR " \
                                           'support if the problem continues.')
        expect(rendered_page).to have_link('Cancel', href: "/objects/#{druid}")
      end
    end

    context 'when the object is a collection' do
      let(:cocina_object) do
        build(:collection_with_metadata, id: druid, title: 'My collection').new(
          identification: { catalogLinks: [{ catalog: 'folio', catalogRecordId: 'a123', refresh: true }] }
        )
      end

      before { create(:permission, :edit, workgroup: user.groups.first, target_druid: druid) }

      it 'offers only depositing' do
        get "/objects/#{druid}/folio_refresh/new"

        expect(response).to have_http_status(:ok)
        expect(rendered_page).to have_no_button('Refresh from FOLIO and save as draft')
        expect(rendered_page).to have_button('Refresh from FOLIO and deposit')
      end
    end

    context 'when the object has no FOLIO Instance HRID marked Refresh on deposit' do
      let(:cocina_object) { build(:dro_with_metadata, id: druid, title: 'My item', version: 2) }

      before { create(:permission, :edit, workgroup: user.groups.first, target_druid: druid) }

      it 'redirects to the object page with a warning' do
        get "/objects/#{druid}/folio_refresh/new"

        expect(response).to redirect_to(object_path(druid))
        expect(flash[:warning]).to eq('This object has no FOLIO Instance HRID to refresh from.')
      end
    end

    context 'when the object is not editable' do
      let(:version_service) { version_service_double(version: 2, assembling?: true, closeable?: false) }

      before { create(:permission, :edit, workgroup: user.groups.first, target_druid: druid) }

      it 'redirects to the object page with a warning' do
        get "/objects/#{druid}/folio_refresh/new"

        expect(response).to redirect_to(object_path(druid))
        expect(flash[:warning]).to eq('This object is not editable.')
      end
    end

    context 'when the user cannot edit the object' do
      it 'redirects to the root' do
        get "/objects/#{druid}/folio_refresh/new"

        expect(response).to redirect_to(root_path)
        expect(flash[:danger]).to eq('You are not authorized to perform the requested action.')
      end
    end
  end

  describe 'create' do
    let(:form_params) { { version_description: 'Updated from FOLIO', retrieved_title: 'Paying for college' } }

    context 'when depositing a deposited item' do
      before { create(:permission, :edit, workgroup: user.groups.first, target_druid: druid) }

      it 'opens a version, refreshes as the user, and starts accessioning' do
        post "/objects/#{druid}/folio_refresh", params: { folio_refresh: form_params, commit: 'deposit' }

        expect(response).to redirect_to(object_path(druid))
        expect(flash[:toast]).to eq('Description refreshed from FOLIO and deposit started.')
        expect(version_service).to have_received(:open)
          .with(description: 'Updated from FOLIO', opening_user_name: user.sunetid)
        expect(object_client).to have_received(:refresh_descriptive_metadata_from_ils).with(user_name: user.sunetid)
        expect(Sdr::Repository).to have_received(:accession)
          .with(cocina_object: refreshed_cocina_object, user_name: user.sunetid, lane_id: 'high', context: {})
        expect(FolioClient).not_to have_received(:fetch_instance_info)
      end
    end

    context 'when saving a Draft' do
      let(:version_service) { version_service_double(version: 2, version_description: 'Fixing the title', open: nil) }

      before do
        create(:permission, :edit, workgroup: user.groups.first, target_druid: druid)
        create(:content, :mutable, druid:, lock: cocina_object.lock)
      end

      it 'refreshes, then updates the version description, and keeps the Content on the refreshed object' do
        post "/objects/#{druid}/folio_refresh", params: { folio_refresh: form_params, commit: 'draft' }

        expect(response).to redirect_to(object_path(druid))
        expect(flash[:toast]).to eq('Description refreshed from FOLIO.')
        expect(version_service).not_to have_received(:open)
        expect(object_client).to have_received(:refresh_descriptive_metadata_from_ils).ordered
        expect(version_service).to have_received(:update_description)
          .with(description: 'Updated from FOLIO', user_name: user.sunetid).ordered
        expect(Content.find_by(druid:, immutable: false).lock).to eq 'refreshed-lock'
        expect(Sdr::Repository).not_to have_received(:accession)
      end
    end

    context 'when depositing a Draft whose files have unsaved changes' do
      let(:version_service) { version_service_double(version: 2, version_description: 'Fixing the title') }

      before do
        create(:permission, :edit, workgroup: user.groups.first, target_druid: druid)
        content = create(:content, :mutable, druid:, lock: cocina_object.lock)
        create(:content_file_binary, content:, file_location: 'attached')
      end

      it 'renders the page with the error without refreshing' do
        post "/objects/#{druid}/folio_refresh", params: { folio_refresh: form_params, commit: 'deposit' }

        expect(response).to have_http_status(:unprocessable_content)
        expect(rendered_page).to have_css('.alert-danger', text: 'Files have unsaved changes.')
        expect(object_client).not_to have_received(:refresh_descriptive_metadata_from_ils)
      end
    end

    context 'when depositing a collection' do
      let(:cocina_object) do
        build(:collection_with_metadata, id: druid, title: 'My collection', version: 2).new(
          identification: { catalogLinks: [{ catalog: 'folio', catalogRecordId: 'a123', refresh: true }] }
        )
      end

      before { create(:permission, :edit, workgroup: user.groups.first, target_druid: druid) }

      it 'refreshes and starts accessioning' do
        post "/objects/#{druid}/folio_refresh", params: { folio_refresh: form_params, commit: 'deposit' }

        expect(response).to redirect_to(object_path(druid))
        expect(flash[:toast]).to eq('Description refreshed from FOLIO and deposit started.')
        expect(object_client).to have_received(:refresh_descriptive_metadata_from_ils)
        expect(Sdr::Repository).to have_received(:accession)
      end
    end

    context 'when the version description is blank' do
      let(:form_params) { { version_description: '', retrieved_title: 'Paying for college' } }

      before { create(:permission, :edit, workgroup: user.groups.first, target_druid: druid) }

      it 'renders the page with the error without refreshing' do
        post "/objects/#{druid}/folio_refresh", params: { folio_refresh: form_params, commit: 'deposit' }

        expect(response).to have_http_status(:unprocessable_content)
        expect(rendered_page).to have_css('#folio_refresh_version_description_error')
        expect(rendered_page).to have_css('dd', text: 'Paying for college')
        expect(object_client).not_to have_received(:refresh_descriptive_metadata_from_ils)
        expect(FolioClient).not_to have_received(:fetch_instance_info)
      end
    end

    context 'when the mutable Content is busy' do
      let(:version_service) { version_service_double(version: 2, version_description: 'Fixing the title') }

      before do
        create(:permission, :edit, workgroup: user.groups.first, target_druid: druid)
        create(:content, :mutable, druid:, lock: cocina_object.lock, staging_state: 'staging')
      end

      it 'redirects to the object page with a warning without refreshing' do
        post "/objects/#{druid}/folio_refresh", params: { folio_refresh: form_params, commit: 'deposit' }

        expect(response).to redirect_to(object_path(druid))
        expect(flash[:warning]).to eq('Files for this item are being staged, discovered, or structured. ' \
                                      'Try again when that has finished.')
        expect(object_client).not_to have_received(:refresh_descriptive_metadata_from_ils)
      end
    end

    context 'when the refresh fails' do
      let(:response_double) do
        instance_double(Faraday::Response, status: 500, body: nil, reason_phrase: 'FOLIO is down')
      end

      before do
        create(:permission, :edit, workgroup: user.groups.first, target_druid: druid)
        allow(object_client).to receive(:refresh_descriptive_metadata_from_ils)
          .and_raise(Dor::Services::Client::UnexpectedResponse.new(response: response_double))
      end

      it 'renders the page with an error without depositing' do
        post "/objects/#{druid}/folio_refresh", params: { folio_refresh: form_params, commit: 'deposit' }

        expect(response).to have_http_status(:unprocessable_content)
        expect(rendered_page).to have_css('.alert-danger', text: "The description couldn't be refreshed from " \
                                                                 'FOLIO. Try again, or contact SDR support if ' \
                                                                 'the problem continues.')
        expect(rendered_page).to have_field('Version description', with: 'Updated from FOLIO')
        expect(Sdr::Repository).not_to have_received(:accession)
      end
    end

    context 'when the deposit fails after refreshing' do
      let(:deposit_version_service) { version_service_double(version: 3, closeable?: false) }

      before { create(:permission, :edit, workgroup: user.groups.first, target_druid: druid) }

      it 'redirects to the object page with an error' do
        post "/objects/#{druid}/folio_refresh", params: { folio_refresh: form_params, commit: 'deposit' }

        expect(response).to redirect_to(object_path(druid))
        expect(flash[:danger]).to eq("Description refreshed from FOLIO, but the deposit couldn't be started " \
                                     '(Draft cannot be deposited). Try depositing again, or contact SDR support ' \
                                     'if the problem continues.')
        expect(object_client).to have_received(:refresh_descriptive_metadata_from_ils)
        expect(Sdr::Repository).not_to have_received(:accession)
      end
    end

    context 'when the user cannot edit the object' do
      it 'redirects to the root without refreshing' do
        post "/objects/#{druid}/folio_refresh", params: { folio_refresh: form_params, commit: 'deposit' }

        expect(response).to redirect_to(root_path)
        expect(object_client).not_to have_received(:refresh_descriptive_metadata_from_ils)
      end
    end
  end
end
