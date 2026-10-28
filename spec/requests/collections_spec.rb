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
        expect(flash[:warning]).to eq('You are not authorized to perform the requested action.')
        expect(Sdr::Repository).not_to have_received(:register)
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
      expect(flash[:warning]).to eq('You are not authorized to perform the requested action.')
    end

    it 'denies creating a collection' do
      post '/collections', params: { collection: { title: 'My collection', apo_druid: } }

      expect(response).to redirect_to(root_path)
      expect(Sdr::Repository).not_to have_received(:register)
    end
  end
end
