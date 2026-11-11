# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Item releases' do
  let(:user) { create(:user, :reader) }
  let(:druid) { 'druid:bc123df4567' }
  let(:access) { { view: 'world', download: 'world' } }
  let(:cocina_object) { build(:dro_with_metadata, id: druid, title: 'My item').new(access:) }
  let(:release_tags) do
    [Dor::Services::Client::ReleaseTag.new(to: 'Searchworks', release: true, what: 'self',
                                           date: '2026-01-01T00:00:00Z')]
  end

  before do
    allow(Sdr::Repository).to receive_messages(find: cocina_object, release_tags:)
    allow(Sdr::Repository).to receive(:create_release_tag)
    sign_in(user)
  end

  describe 'new' do
    context 'when the user can edit the item' do
      before { create(:permission, :edit, workgroup: user.groups.first, target_druid: druid) }

      it 'renders the form with tagged targets selected and unable to follow the collection' do
        get "/items/#{druid}/releases/new"

        expect(response).to have_http_status(:ok)
        expect(Sdr::Repository).to have_received(:find).with(druid:, without_structural_contains: true)
        expect(Sdr::Repository).to have_received(:release_tags).with(druid:, public: false)
        page = Capybara.string(response.body)
        expect(page).to have_css('h1', text: 'Manage release')
        expect(page).to have_text('My item')
        expect(page).to have_select('SearchWorks', selected: 'Release',
                                                   options: ['Follow collection settings', 'Release', 'Do not release'],
                                                   disabled_options: ['Follow collection settings'])
        expect(page).to have_select('Search engines', selected: 'Follow collection settings', disabled_options: [])
        expect(page).to have_link('Cancel', href: "/objects/#{druid}")
      end
    end

    context 'when the item is dark' do
      let(:access) { { view: 'dark', download: 'none' } }

      before { create(:permission, :edit, workgroup: user.groups.first, target_druid: druid) }

      it 'redirects to the object page with an error' do
        get "/items/#{druid}/releases/new"

        expect(response).to redirect_to(object_path(druid))
        expect(flash[:danger]).to eq('Dark objects cannot be released.')
      end
    end

    context 'when the user cannot edit the item' do
      it 'redirects to the root' do
        get "/items/#{druid}/releases/new"

        expect(response).to redirect_to(root_path)
        expect(flash[:danger]).to eq(I18n.t('errors.not_authorized'))
      end
    end
  end

  describe 'create' do
    let(:release_params) do
      { searchworks_target: 'release_to_targets', earthworks_target: 'no_release',
        purl_sitemap_target: 'release_to_collection' }
    end

    context 'when the user can edit the item' do
      before { create(:permission, :edit, workgroup: user.groups.first, target_druid: druid) }

      it 'creates release tags for changed targets and redirects with a toast' do
        post "/items/#{druid}/releases", params: { item_release_tags: release_params }

        expect(Sdr::Repository).to have_received(:create_release_tag).once
        expect(Sdr::Repository).to have_received(:create_release_tag)
          .with(druid:, user_name: user.sunetid, release_target: 'Earthworks', release: false)
        expect(response).to redirect_to(object_path(druid))
        expect(flash[:toast]).to eq('Release updated')
      end

      context 'when no target is changed' do
        let(:release_params) do
          { searchworks_target: 'release_to_targets', earthworks_target: 'release_to_collection',
            purl_sitemap_target: 'release_to_collection' }
        end

        it 'redirects without a toast' do
          post "/items/#{druid}/releases", params: { item_release_tags: release_params }

          expect(Sdr::Repository).not_to have_received(:create_release_tag)
          expect(response).to redirect_to(object_path(druid))
          expect(flash[:toast]).to be_nil
        end
      end

      context 'when creating a release tag fails' do
        before { allow(Sdr::Repository).to receive(:create_release_tag).and_raise(Sdr::Repository::Error) }

        it 'renders the form with an alert' do
          post "/items/#{druid}/releases", params: { item_release_tags: release_params }

          expect(response).to have_http_status(:unprocessable_content)
          expect(response.body).to include('The release could not be saved.')
          page = Capybara.string(response.body)
          expect(page).to have_select('SearchWorks', disabled_options: ['Follow collection settings'])
        end
      end
    end

    context 'when the item is dark' do
      let(:access) { { view: 'dark', download: 'none' } }

      before { create(:permission, :edit, workgroup: user.groups.first, target_druid: druid) }

      it 'redirects to the object page with an error without creating release tags' do
        post "/items/#{druid}/releases", params: { item_release_tags: release_params }

        expect(Sdr::Repository).not_to have_received(:create_release_tag)
        expect(response).to redirect_to(object_path(druid))
        expect(flash[:danger]).to eq('Dark objects cannot be released.')
      end
    end

    context 'when the user cannot edit the item' do
      it 'redirects to the root' do
        post "/items/#{druid}/releases", params: { item_release_tags: release_params }

        expect(Sdr::Repository).not_to have_received(:create_release_tag)
        expect(response).to redirect_to(root_path)
        expect(flash[:danger]).to eq(I18n.t('errors.not_authorized'))
      end
    end
  end
end
