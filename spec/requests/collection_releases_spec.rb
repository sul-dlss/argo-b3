# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Collection releases' do
  let(:user) { create(:user, :reader) }
  let(:druid) { 'druid:bc123df4567' }
  let(:access) { { view: 'world' } }
  let(:cocina_object) { build(:collection_with_metadata, id: druid, title: 'My collection').new(access:) }
  let(:release_tags) do
    [Dor::Services::Client::ReleaseTag.new(to: 'Searchworks', release: true, what: 'self',
                                           date: '2026-01-01T00:00:00Z', who: 'someone')]
  end

  before do
    allow(Sdr::Repository).to receive_messages(find: cocina_object, release_tags:)
    allow(Sdr::Repository).to receive(:create_release_tag)
    sign_in(user)
  end

  describe 'new' do
    context 'when the user can edit the collection' do
      before { create(:permission, :edit, workgroup: user.groups.first, target_druid: druid) }

      it 'renders the form with each target released as its latest tag releases it' do
        get "/collections/#{druid}/releases/new"

        expect(response).to have_http_status(:ok)
        expect(Sdr::Repository).to have_received(:release_tags).with(druid:, public: false)
        page = Capybara.string(response.body)
        expect(page).to have_css('h1', text: 'Manage release')
        expect(page).to have_text('My collection')
        expect(page).to have_checked_field('collection_release_tags[searchworks_release]')
        expect(page).to have_checked_field('collection_release_tags_searchworks_what_self')
        expect(page).to have_unchecked_field('collection_release_tags[earthworks_release]')
        expect(page).to have_link('Cancel', href: "/objects/#{druid}")
      end
    end

    context 'when the collection is dark' do
      let(:access) { { view: 'dark' } }

      before { create(:permission, :edit, workgroup: user.groups.first, target_druid: druid) }

      it 'redirects to the object page with an error' do
        get "/collections/#{druid}/releases/new"

        expect(response).to redirect_to(object_path(druid))
        expect(flash[:danger]).to eq('Dark objects cannot be released.')
      end
    end

    context 'when the user cannot edit the collection' do
      it 'redirects to the root' do
        get "/collections/#{druid}/releases/new"

        expect(response).to redirect_to(root_path)
        expect(flash[:danger]).to eq(I18n.t('errors.not_authorized'))
      end
    end
  end

  describe 'create' do
    let(:release_params) do
      { searchworks_release: '1', searchworks_what: 'self', earthworks_release: '1', earthworks_what: 'collection',
        purl_sitemap_release: '0' }
    end

    context 'when the user can edit the collection' do
      before { create(:permission, :edit, workgroup: user.groups.first, target_druid: druid) }

      it 'creates release tags for changed targets and redirects with a toast' do
        post "/collections/#{druid}/releases", params: { collection_release_tags: release_params }

        expect(Sdr::Repository).to have_received(:create_release_tag).once
        expect(Sdr::Repository).to have_received(:create_release_tag)
          .with(druid:, user_name: user.sunetid, release_target: 'Earthworks', release: true,
                release_what: 'collection', date: Time)
        expect(response).to redirect_to(object_path(druid))
        expect(flash[:toast]).to eq('Release updated')
      end

      context 'when no target is changed' do
        let(:release_params) { { searchworks_release: '1', searchworks_what: 'self', earthworks_release: '0' } }

        it 'redirects without a toast' do
          post "/collections/#{druid}/releases", params: { collection_release_tags: release_params }

          expect(Sdr::Repository).not_to have_received(:create_release_tag)
          expect(response).to redirect_to(object_path(druid))
          expect(flash[:toast]).to be_nil
        end
      end

      context 'when creating a release tag fails' do
        before { allow(Sdr::Repository).to receive(:create_release_tag).and_raise(Sdr::Repository::Error) }

        it 'renders the form with an alert' do
          post "/collections/#{druid}/releases", params: { collection_release_tags: release_params }

          expect(response).to have_http_status(:unprocessable_content)
          expect(response.body).to include('The release could not be saved.')
          page = Capybara.string(response.body)
          expect(page).to have_checked_field('collection_release_tags_earthworks_what_collection')
        end
      end
    end

    context 'when the collection is dark' do
      let(:access) { { view: 'dark' } }

      before { create(:permission, :edit, workgroup: user.groups.first, target_druid: druid) }

      it 'redirects to the object page with an error without creating release tags' do
        post "/collections/#{druid}/releases", params: { collection_release_tags: release_params }

        expect(Sdr::Repository).not_to have_received(:create_release_tag)
        expect(response).to redirect_to(object_path(druid))
        expect(flash[:danger]).to eq('Dark objects cannot be released.')
      end
    end

    context 'when the user cannot edit the collection' do
      it 'redirects to the root' do
        post "/collections/#{druid}/releases", params: { collection_release_tags: release_params }

        expect(Sdr::Repository).not_to have_received(:create_release_tag)
        expect(response).to redirect_to(root_path)
        expect(flash[:danger]).to eq(I18n.t('errors.not_authorized'))
      end
    end
  end
end
