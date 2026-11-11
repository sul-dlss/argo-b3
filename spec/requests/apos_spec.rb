# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'APOs' do
  let(:user) { create(:user, :admin) }

  before do
    allow(Searchers::AgreementList).to receive(:call).and_return([['My Agreement', 'druid:bc123df4567']])
    sign_in(user)
  end

  describe 'new' do
    it 'renders the agreement select' do
      get '/apos/new'

      expect(response).to have_http_status(:ok)
      page = Capybara.string(response.body)
      expect(page).to have_select('Agreement', options: ['My Agreement'])
      expect(page).to have_css('label', text: 'Agreement') { |label| label.has_css?('span.required', text: '*') }
      expect(Searchers::AgreementList).to have_received(:call).with(user_scope: an_instance_of(Permissions::UserScope))
    end

    it 'renders the object defaults fieldset' do
      get '/apos/new'

      page = Capybara.string(response.body)
      expect(page).to have_css('fieldset legend label.h3', text: 'Object defaults')
      expect(page).to have_css('fieldset', text: 'The following defaults will apply to all newly registered objects.')
      expect(page).to have_css('fieldset select[name="apo[access_view]"]')
      expect(page).to have_css('fieldset select[name="apo[access_download]"]')
      expect(page).to have_css('fieldset select[name="apo[access_location]"]', visible: :all)
    end

    it 'renders the cancel and submit buttons' do
      get '/apos/new'

      page = Capybara.string(response.body)
      expect(page).to have_link('Cancel', href: '/')
      expect(page).to have_button('Register and deposit APO')
    end
  end

  describe 'create' do
    context 'when valid' do
      let(:registered_cocina_object) { build(:admin_policy_with_metadata, id: 'druid:xz987wv6543') }

      before do
        allow(Sdr::Repository).to receive_messages(register: registered_cocina_object, accession: nil)
      end

      it 'registers and accessions the APO, governed by the uber APO' do
        post '/apos', params: { apo: { title: 'My APO', agreement_druid: 'druid:bc123df4567',
                                       apo_druid: 'druid:dd111dd1111',
                                       access_view: 'world', access_download: 'world', license: '' } }

        expect(response).to redirect_to('/objects/druid:xz987wv6543')
        expect(flash[:toast]).to eq('APO registered and deposit started')
        expect(Sdr::Repository).to have_received(:register) do |args|
          request_cocina_object = args[:request_cocina_object]
          expect(request_cocina_object.description.title.first.value).to eq('My APO')
          expect(request_cocina_object.administrative.hasAdminPolicy).to eq(Settings.ur_apo_druid)
          expect(request_cocina_object.administrative.hasAgreement).to eq('druid:bc123df4567')
          expect(request_cocina_object.administrative.accessTemplate.license).to be_nil
        end
        expect(Sdr::Repository).to have_received(:accession)
          .with(cocina_object: registered_cocina_object, user_name: user.sunetid)
      end
    end

    context 'when invalid' do
      it 'renders the agreement select with the selected agreement' do
        # No title is provided, so the APO is invalid.
        post '/apos', params: { apo: { agreement_druid: 'druid:bc123df4567' } }

        expect(response).to have_http_status(:unprocessable_content)
        page = Capybara.string(response.body)
        expect(page).to have_select('Agreement', selected: 'My Agreement')
      end
    end
  end

  describe 'edit' do
    let(:user) { create(:user) }
    let(:druid) { 'druid:xz987wv6543' }
    let(:permission_target_druid) { druid }
    let(:cocina_object) do
      build(:admin_policy_with_metadata, id: druid, title: 'My APO').new(
        administrative: {
          hasAdminPolicy: 'druid:hv992ry2431',
          hasAgreement: 'druid:bc123df4567',
          accessTemplate: { view: 'world', download: 'world', copyright: 'Copyright © Stanford.' }
        }
      )
    end
    let(:version_service) do
      version_service_double(open?: open, editable?: editable, version_description: 'Fixing the title')
    end
    let(:open) { true }
    let(:editable) { true }

    before do
      create(:permission, :edit, workgroup: user.groups.first, target_druid: permission_target_druid)
      allow(Sdr::Repository).to receive(:find).and_return(cocina_object)
      allow(Sdr::VersionService).to receive(:new).and_return(version_service)
    end

    it 'renders the form with the current values' do
      get "/apos/#{druid}/edit"

      expect(response).to have_http_status(:ok)
      page = Capybara.string(response.body)
      expect(page).to have_css('h1', text: 'Edit and deposit APO')
      expect(page).to have_css('h1 + p', text: 'My APO')
      expect(page).to have_field('Title', with: 'My APO')
      expect(page).to have_select('Agreement', selected: 'My Agreement')
      expect(page).to have_select('View access', selected: 'World')
      expect(page).to have_field('Default copyright', with: 'Copyright © Stanford.')
      expect(page).to have_field('apo[lock]', type: :hidden, with: cocina_object.lock)
      expect(Sdr::Repository).to have_received(:find).with(druid:)
    end

    it 'prefills the required version description from the open version' do
      get "/apos/#{druid}/edit"

      page = Capybara.string(response.body)
      expect(page).to have_field('Version description', with: 'Fixing the title')
      expect(page).to have_css('label', text: 'Version description') { |label| label.has_css?('span.required') }
    end

    it 'renders the cancel and deposit buttons' do
      get "/apos/#{druid}/edit"

      page = Capybara.string(response.body)
      expect(page).to have_link('Cancel', href: "/objects/#{druid}")
      expect(page).to have_button('Deposit')
    end

    context 'when the user cannot otherwise select the current agreement' do
      before do
        allow(Searchers::AgreementList).to receive(:call).and_return([['My other agreement', 'druid:cd234fg5678']])
      end

      it 'adds the agreement as an option labeled with its druid, so that saving does not change it' do
        get "/apos/#{druid}/edit"

        expect(Capybara.string(response.body))
          .to have_select('Agreement', selected: 'bc123df4567', options: ['bc123df4567', 'My other agreement'])
      end
    end

    context 'when the version is closed' do
      let(:open) { false }

      it 'renders an empty version description' do
        get "/apos/#{druid}/edit"

        expect(Capybara.string(response.body).find_field('Version description').value).to be_blank
      end
    end

    context 'when the version is not editable' do
      let(:editable) { false }

      it 'redirects to the object page with an error' do
        get "/apos/#{druid}/edit"

        expect(response).to redirect_to("/objects/#{druid}")
        expect(flash[:danger]).to eq('APO is not editable.')
      end
    end

    context 'when the user cannot edit the APO' do
      let(:permission_target_druid) { 'druid:cd234fg5678' }

      it 'denies access' do
        get "/apos/#{druid}/edit"

        expect(response).to redirect_to(root_path)
        expect(flash[:danger]).to eq('You are not authorized to perform the requested action.')
      end
    end
  end

  describe 'update' do
    let(:user) { create(:user) }
    let(:druid) { 'druid:xz987wv6543' }
    let(:permission_target_druid) { druid }
    let(:cocina_object) { build(:admin_policy_with_metadata, id: druid, title: 'My APO') }
    let(:opened_cocina_object) { cocina_object.new(version: 2, lock: 'opened-lock') }
    let(:version_service) { version_service_double(open?: false, openable?: true, closeable?: false, closed?: true) }
    let(:apo_params) do
      { title: 'My new APO', agreement_druid: 'druid:bc123df4567', access_view: 'stanford',
        access_download: 'stanford', version_description: 'Changed the title', lock: cocina_object.lock }
    end

    before do
      create(:permission, :edit, workgroup: user.groups.first, target_druid: permission_target_druid)
      allow(Sdr::Repository).to receive(:find).and_return(cocina_object)
      allow(Sdr::Repository).to receive(:update) { |cocina_object:, **| cocina_object }
      allow(Sdr::Repository).to receive(:accession)
      allow(Sdr::VersionService).to receive_messages(new: version_service, open: opened_cocina_object)
    end

    it 'opens a version, saves, and starts accessioning' do
      patch "/apos/#{druid}", params: { apo: apo_params }

      expect(response).to redirect_to("/objects/#{druid}")
      expect(flash[:toast]).to eq('APO updated and deposit started.')
      expect(Sdr::VersionService).to have_received(:open)
        .with(druid:, description: 'Changed the title', opening_user_name: user.sunetid)
      expect(Sdr::Repository).to have_received(:update) do |args|
        updated_cocina_object = args[:cocina_object]
        expect(updated_cocina_object.lock).to eq('opened-lock')
        expect(updated_cocina_object.description.title.first.value).to eq('My new APO')
        expect(updated_cocina_object.administrative.hasAgreement).to eq('druid:bc123df4567')
        expect(updated_cocina_object.administrative.accessTemplate.view).to eq('stanford')
        expect(args[:user_name]).to eq(user.sunetid)
      end
      expect(Sdr::Repository).to have_received(:accession)
        .with(cocina_object: having_attributes(lock: 'opened-lock'), user_name: user.sunetid, context: {})
    end

    it 'does not change the governing APO' do
      patch "/apos/#{druid}", params: { apo: apo_params.merge(apo_druid: 'druid:cd234fg5678') }

      expect(Sdr::Repository).to have_received(:update)
        .with(hash_including(cocina_object: having_attributes(
          administrative: having_attributes(hasAdminPolicy: cocina_object.administrative.hasAdminPolicy)
        )))
    end

    context 'when the version description is missing' do
      it 'renders the form with the error without saving' do
        patch "/apos/#{druid}", params: { apo: apo_params.merge(version_description: '') }

        expect(response).to have_http_status(:unprocessable_content)
        page = Capybara.string(response.body)
        expect(page).to have_css('h1', text: 'Edit and deposit APO')
        # The saved title, not the submitted one.
        expect(page).to have_css('h1 + p', text: 'My APO')
        expect(page).to have_no_css('h1 + p', text: 'My new APO')
        expect(page).to have_css('.invalid-feedback', text: "can't be blank")
        expect(page).to have_select('Agreement', selected: 'My Agreement')
        expect(Sdr::Repository).not_to have_received(:update)
        expect(Sdr::Repository).not_to have_received(:accession)
      end
    end

    context 'when the APO was changed since the form was loaded' do
      it 'redirects to the edit page with an error without saving' do
        patch "/apos/#{druid}", params: { apo: apo_params.merge(lock: 'stale-lock') }

        expect(response).to redirect_to("/apos/#{druid}/edit")
        expect(flash[:danger]).to eq('This APO was changed since you opened it. ' \
                                     'Review the current values and make your changes again.')
        expect(Sdr::Repository).not_to have_received(:update)
      end
    end

    context 'when the version is not editable' do
      let(:version_service) { version_service_double(open?: false, openable?: false, closeable?: false) }

      it 'redirects to the object page with an error without saving' do
        patch "/apos/#{druid}", params: { apo: apo_params }

        expect(response).to redirect_to("/objects/#{druid}")
        expect(flash[:danger]).to eq('APO is not editable.')
        expect(Sdr::Repository).not_to have_received(:update)
      end
    end

    context 'when the user cannot edit the APO' do
      let(:permission_target_druid) { 'druid:cd234fg5678' }

      it 'denies access' do
        patch "/apos/#{druid}", params: { apo: apo_params }

        expect(response).to redirect_to(root_path)
        expect(Sdr::Repository).not_to have_received(:update)
      end
    end
  end

  context 'when the user is not an admin' do
    let(:user) { create(:user) }

    before do
      allow(Sdr::Repository).to receive(:register)
    end

    it 'denies access to the new APO form' do
      get '/apos/new'

      expect(response).to redirect_to(root_path)
      expect(flash[:danger]).to eq('You are not authorized to perform the requested action.')
    end

    it 'denies creating an APO' do
      post '/apos', params: { apo: { title: 'My APO', agreement_druid: 'druid:bc123df4567' } }

      expect(response).to redirect_to(root_path)
      expect(Sdr::Repository).not_to have_received(:register)
    end
  end
end
