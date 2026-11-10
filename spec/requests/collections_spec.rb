# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Collections' do
  let(:user) { create(:user, groups: [workgroup]) }
  let(:workgroup) { 'sdr:test-workgroup' }
  let(:apo_druid) { 'druid:hv992ry2431' }

  before do
    create(:permission, :edit, workgroup:, target_druid: apo_druid)
    allow(Searchers::AdminPolicyList).to receive(:call).and_return([['My APO', apo_druid]])
    sign_in(user)
  end

  describe 'new' do
    it 'cancels to the dashboard when coming from another register form' do
      get '/collections/new', headers: { 'HTTP_REFERER' => 'http://www.example.com/items/new' }

      expect(Capybara.string(response.body)).to have_link('Cancel', href: '/')
    end

    it 'renders the collection form with the APOs the user can edit' do
      get '/collections/new'

      expect(response).to have_http_status(:ok)
      page = Capybara.string(response.body)
      expect(page).to have_css('h1', text: 'Register and deposit collection')
      expect(page).to have_field('collection[title]')
      expect(page).to have_field('collection[catalog_record_id]')
      expect(page).to have_no_field('collection[description_csv_file]')
      expect(page).to have_no_field('collection[barcode]')
      expect(page).to have_select('collection[apo_druid]', options: ['My APO'])
      expect(page).to have_select('collection[access_view]', selected: 'world', options: %w[world dark])
      expect(page).to have_select('collection[release_tags_attributes][searchworks_target]',
                                  selected: 'Do not release')
      expect(page).to have_field('collection[other_tags_attributes][0][tag]')
      expect(page).to have_button('Register and deposit collection')
      expect(Searchers::AdminPolicyList).to have_received(:call).with(user_scope: Permissions::UserScope,
                                                                      editable: true)
    end
  end

  describe 'create' do
    let(:registered_cocina_object) { build(:collection_with_metadata, id: 'druid:xz987wv6543') }
    let(:collection_params) do
      { title: 'My collection', description_choice: 'title', apo_druid:, access_view: 'dark',
        use_and_reproduction_statement: 'Use at will.', copyright: 'Copyright © Stanford.',
        license: 'https://creativecommons.org/licenses/by/4.0/legalcode',
        release_tags_attributes: { searchworks_target: 'self' } }
    end

    before do
      allow(Sdr::Repository).to receive(:register).and_return(registered_cocina_object)
      allow(Sdr::Repository).to receive(:create_release_tag)
      allow(Sdr::Repository).to receive(:accession)
    end

    context 'when valid' do
      it 'registers, releases, and deposits the collection' do
        post '/collections', params: { collection: collection_params }

        expect(response).to redirect_to('/objects/druid:xz987wv6543')
        expect(flash[:toast]).to eq('Collection registered and deposit started.')
        expect(Sdr::Repository).to have_received(:register) do |args|
          request_cocina_object = args[:request_cocina_object]
          expect(request_cocina_object.description.title.first.value).to eq('My collection')
          expect(request_cocina_object.administrative.hasAdminPolicy).to eq(apo_druid)
          expect(request_cocina_object.access.view).to eq('dark')
          expect(request_cocina_object.access.useAndReproductionStatement).to eq('Use at will.')
          expect(request_cocina_object.access.copyright).to eq('Copyright © Stanford.')
          expect(request_cocina_object.access.license).to eq('https://creativecommons.org/licenses/by/4.0/legalcode')
        end
        expect(Sdr::Repository).to have_received(:create_release_tag)
          .with(druid: 'druid:xz987wv6543', user_name: user.sunetid, release_target: 'Searchworks', release: true,
                release_what: 'self')
        expect(Sdr::Repository).to have_received(:accession)
      end
    end

    context 'when invalid' do
      it 'renders the form' do
        post '/collections', params: { collection: collection_params.merge(title: '') }

        expect(response).to have_http_status(:unprocessable_content)
        expect(Capybara.string(response.body)).to have_css('.invalid-feedback', text: "can't be blank")
        expect(Sdr::Repository).not_to have_received(:register)
      end
    end

    context 'when no APO is selected' do
      it 'renders the form with an APO error' do
        post '/collections', params: { collection: collection_params.merge(apo_druid: '') }

        expect(response).to have_http_status(:unprocessable_content)
        expect(Capybara.string(response.body)).to have_css('.invalid-feedback', text: "can't be blank")
        expect(Sdr::Repository).not_to have_received(:register)
      end
    end

    context 'when the selected APO is a collection the user can edit' do
      let(:collection_druid) { 'druid:cd456gh7890' }

      before { create(:permission, :edit, workgroup:, target_druid: collection_druid) }

      it 'renders the form with an APO error' do
        post '/collections', params: { collection: collection_params.merge(apo_druid: collection_druid) }

        expect(response).to have_http_status(:unprocessable_content)
        expect(Capybara.string(response.body)).to have_css('.invalid-feedback', text: 'must be an APO you can edit')
        expect(Sdr::Repository).not_to have_received(:register)
      end

      it 'does not permit the selectable APOs to be submitted' do
        post '/collections', params: { collection: collection_params.merge(apo_druid: collection_druid,
                                                                           selectable_apo_druids: [collection_druid]) }

        expect(response).to have_http_status(:unprocessable_content)
        expect(Sdr::Repository).not_to have_received(:register)
      end
    end

    context 'when the user is an admin' do
      let(:user) { create(:user, :admin) }

      it 'registers, releases, and deposits the collection' do
        post '/collections', params: { collection: collection_params }

        expect(response).to redirect_to('/objects/druid:xz987wv6543')
        expect(Sdr::Repository).to have_received(:register)
      end
    end

    context 'when the user cannot edit the selected APO' do
      it 'denies creating the collection' do
        post '/collections', params: { collection: collection_params.merge(apo_druid: 'druid:bc123df4567') }

        expect(response).to redirect_to(root_path)
        expect(flash[:danger]).to eq('You are not authorized to perform the requested action.')
        expect(Sdr::Repository).not_to have_received(:register)
      end
    end
  end

  describe 'edit' do
    let(:druid) { 'druid:xz987wv6543' }
    let(:cocina_object) do
      build(:collection_with_metadata, id: druid, title: 'My collection', admin_policy_id: apo_druid).new(
        access: { view: 'world', copyright: 'Copyright © Stanford.' },
        identification: { catalogLinks: [{ catalog: 'folio', catalogRecordId: 'a12345', refresh: true }],
                          sourceId: 'sulcollection:1234' }
      )
    end
    let(:version_service) do
      version_service_double(open?: open, editable?: editable, version_description: 'Refreshing from FOLIO')
    end
    let(:open) { true }
    let(:editable) { true }

    before do
      allow(Sdr::Repository).to receive(:find).and_return(cocina_object)
      allow(Sdr::VersionService).to receive(:new).and_return(version_service)
    end

    it 'renders the form with the current values' do
      get "/collections/#{druid}/edit"

      expect(response).to have_http_status(:ok)
      page = Capybara.string(response.body)
      expect(page).to have_css('h1', text: 'Edit and deposit collection')
      expect(page).to have_css('h1 + p', text: 'My collection')
      expect(page).to have_field('FOLIO Instance HRID', with: 'a12345')
      expect(page).to have_field('Refresh on deposit', checked: true)
      expect(page).to have_css('.alert-info', text: 'If checked, this object will be refreshed every time')
      expect(page).to have_field('collection[description_csv_file]', type: 'file')
      expect(page).to have_no_field('Barcode')
      expect(page).to have_no_text('Save as draft')
      expect(page).to have_select('APO', selected: 'My APO')
      expect(page).to have_button('Apply APO defaults')
      expect(page).to have_select('View access', selected: 'world')
      expect(page).to have_field('collection[copyright]', with: 'Copyright © Stanford.')
      expect(page).to have_field('collection[lock]', type: :hidden, with: cocina_object.lock)
    end

    it 'prefills the required version description from the open version and renders the deposit button' do
      get "/collections/#{druid}/edit"

      page = Capybara.string(response.body)
      expect(page).to have_field('Version description', with: 'Refreshing from FOLIO')
      expect(page).to have_css('label', text: 'Version description') { |label| label.has_css?('span.required') }
      expect(page).to have_link('Cancel', href: "/objects/#{druid}")
      expect(page).to have_button('Deposit')
      expect(page).to have_no_button('Save as draft')
    end

    context 'when the user cannot edit the current APO' do
      let(:user) { create(:user, groups: ['sdr:collection-workgroup']) }

      before do
        create(:permission, :edit, workgroup: 'sdr:collection-workgroup', target_druid: druid)
        allow(Searchers::AdminPolicyList).to receive(:call).and_return([['My other APO', 'druid:cd234fg5678']])
        allow(Searchers::AdminPolicyListByDruid).to receive(:call).and_return([['My APO', apo_druid]])
      end

      it 'adds the current APO as an option, so that saving does not change it' do
        get "/collections/#{druid}/edit"

        expect(Capybara.string(response.body))
          .to have_select('APO', selected: 'My APO', options: ['My APO', 'My other APO'])
      end
    end

    context 'when the version is not editable' do
      let(:editable) { false }

      it 'redirects to the object page with an error' do
        get "/collections/#{druid}/edit"

        expect(response).to redirect_to("/objects/#{druid}")
        expect(flash[:danger]).to eq('Collection is not editable.')
      end
    end

    context 'when the user cannot edit the collection' do
      let(:user) { create(:user, groups: ['sdr:other-workgroup']) }

      it 'denies access' do
        get "/collections/#{druid}/edit"

        expect(response).to redirect_to(root_path)
        expect(flash[:danger]).to eq('You are not authorized to perform the requested action.')
      end
    end
  end

  describe 'update' do
    let(:druid) { 'druid:xz987wv6543' }
    let(:cocina_object) do
      build(:collection_with_metadata, id: druid, title: 'My collection', admin_policy_id: apo_druid)
        .new(access: { view: 'world' })
    end
    let(:opened_cocina_object) { cocina_object.new(version: 2, lock: 'opened-lock') }
    let(:version_service) { version_service_double(open?: false, openable?: true, closeable?: false, closed?: true) }
    let(:collection_params) do
      { apo_druid:, access_view: 'dark', copyright: 'My copyright', version_description: 'Made dark',
        lock: cocina_object.lock }
    end

    before do
      allow(Sdr::Repository).to receive(:find).and_return(cocina_object)
      allow(Sdr::Repository).to receive(:update) { |cocina_object:, **| cocina_object }
      allow(Sdr::Repository).to receive(:accession)
      allow(Sdr::VersionService).to receive_messages(new: version_service, open: opened_cocina_object)
    end

    it 'opens a version, saves, and starts accessioning' do
      patch "/collections/#{druid}", params: { collection: collection_params }

      expect(response).to redirect_to("/objects/#{druid}")
      expect(flash[:toast]).to eq('Collection updated and deposit started.')
      expect(Sdr::VersionService).to have_received(:open)
        .with(druid:, description: 'Made dark', opening_user_name: user.sunetid)
      expect(Sdr::Repository).to have_received(:update) do |args|
        updated_cocina_object = args[:cocina_object]
        expect(updated_cocina_object.lock).to eq('opened-lock')
        expect(updated_cocina_object.access.view).to eq('dark')
        expect(updated_cocina_object.access.copyright).to eq('My copyright')
        expect(args[:user_name]).to eq(user.sunetid)
      end
      expect(Sdr::Repository).to have_received(:accession)
        .with(cocina_object: having_attributes(lock: 'opened-lock'), user_name: user.sunetid, context: {})
    end

    it 'does not change the source id or description from params' do
      patch "/collections/#{druid}",
            params: { collection: collection_params.merge(source_id: 'sul:other', description_hash: { title: [] }) }

      expect(Sdr::Repository).to have_received(:update)
        .with(hash_including(cocina_object: having_attributes(
          identification: having_attributes(sourceId: cocina_object.identification.sourceId),
          description: cocina_object.description
        )))
    end

    context 'when nothing changed' do
      let(:collection_params) do
        { apo_druid:, access_view: 'world', version_description: 'Redeposit', lock: cocina_object.lock }
      end

      it 'opens a version and starts accessioning without saving' do
        patch "/collections/#{druid}", params: { collection: collection_params }

        expect(response).to redirect_to("/objects/#{druid}")
        expect(Sdr::VersionService).to have_received(:open)
        expect(Sdr::Repository).not_to have_received(:update)
        expect(Sdr::Repository).to have_received(:accession)
      end
    end

    context 'when the version description is missing' do
      it 'renders the form with the error without saving' do
        patch "/collections/#{druid}", params: { collection: collection_params.merge(version_description: '') }

        expect(response).to have_http_status(:unprocessable_content)
        page = Capybara.string(response.body)
        expect(page).to have_css('h1', text: 'Edit and deposit collection')
        expect(page).to have_css('.invalid-feedback', text: "can't be blank")
        expect(page).to have_select('View access', selected: 'dark')
        expect(Sdr::Repository).not_to have_received(:update)
        expect(Sdr::Repository).not_to have_received(:accession)
      end
    end

    context 'when Refresh on deposit is checked without a FOLIO Instance HRID' do
      it 'renders the form with the error without saving' do
        patch "/collections/#{druid}",
              params: { collection: collection_params.merge(catalog_record_id: '', catalog_link_refresh: '1') }

        expect(response).to have_http_status(:unprocessable_content)
        expect(Capybara.string(response.body))
          .to have_css('.invalid-feedback', text: 'A FOLIO Instance HRID must be provided to allow Refresh on deposit.')
        expect(Sdr::Repository).not_to have_received(:update)
        expect(Sdr::Repository).not_to have_received(:accession)
      end
    end

    context 'when the collection was changed since the form was loaded' do
      it 'redirects to the form with an error without saving' do
        patch "/collections/#{druid}", params: { collection: collection_params.merge(lock: 'other-lock') }

        expect(response).to redirect_to("/collections/#{druid}/edit")
        expect(flash[:danger]).to eq('This collection was changed since you opened it. ' \
                                     'Review the current values and make your changes again.')
        expect(Sdr::Repository).not_to have_received(:update)
      end
    end

    context 'when the version is not editable' do
      let(:version_service) { version_service_double(open?: false, openable?: false, closeable?: false) }

      it 'redirects to the object page with an error without saving' do
        patch "/collections/#{druid}", params: { collection: collection_params }

        expect(response).to redirect_to("/objects/#{druid}")
        expect(flash[:danger]).to eq('Collection is not editable.')
        expect(Sdr::Repository).not_to have_received(:update)
      end
    end

    context 'when the user cannot edit the collection' do
      let(:user) { create(:user, groups: ['sdr:other-workgroup']) }

      it 'denies access without saving' do
        patch "/collections/#{druid}", params: { collection: collection_params }

        expect(response).to redirect_to(root_path)
        expect(Sdr::Repository).not_to have_received(:update)
      end
    end

    context 'when the user can edit the collection but not the APO it is moved to' do
      let(:other_apo_druid) { 'druid:cd234fg5678' }

      before do
        allow(Searchers::AdminPolicyList).to receive(:call)
          .and_return([['My APO', apo_druid], ['My other APO', other_apo_druid]])
      end

      it 'denies moving the collection without saving' do
        patch "/collections/#{druid}", params: { collection: collection_params.merge(apo_druid: other_apo_druid) }

        expect(response).to redirect_to(root_path)
        expect(flash[:danger]).to eq('You are not authorized to perform the requested action.')
        expect(Sdr::Repository).not_to have_received(:update)
      end
    end

    context 'when the APO is not one the user may select' do
      let(:user) { create(:user, :admin) }

      it 'renders the form with the error without saving' do
        patch "/collections/#{druid}", params: { collection: collection_params.merge(apo_druid: 'druid:cd234fg5678') }

        expect(response).to have_http_status(:unprocessable_content)
        expect(Capybara.string(response.body)).to have_css('.invalid-feedback', text: 'must be an APO you can edit')
        expect(Sdr::Repository).not_to have_received(:update)
      end
    end
  end

  context 'when the user does not have edit permission' do
    let(:user) { create(:user, groups: ['sdr:other-workgroup']) }

    before do
      allow(Sdr::Repository).to receive(:register)
    end

    it 'denies access to the new collection form' do
      get '/collections/new'

      expect(response).to redirect_to(root_path)
      expect(flash[:danger]).to eq('You are not authorized to perform the requested action.')
    end

    it 'denies creating a collection' do
      post '/collections', params: { collection: { title: 'My collection', apo_druid: } }

      expect(response).to redirect_to(root_path)
      expect(Sdr::Repository).not_to have_received(:register)
    end
  end
end
