# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Show object' do
  let(:druid) { 'druid:bc123df4567' }

  before do
    sign_in(create(:user))
  end

  describe 'GET /objects/:druid' do
    context 'when the object is not found' do
      before do
        allow(Sdr::Repository).to receive(:lock).with(druid:).and_return('v1')
        allow(Sdr::Repository).to receive(:find_solr).with(druid:).and_raise(Sdr::Repository::NotFoundResponse)
      end

      it 'renders a 404' do
        get "/objects/#{druid}"

        expect(response).to have_http_status(:not_found)
      end
    end

    context 'when given a bare druid' do
      let(:druid) { 'bc123df4567' }

      before do
        allow(Sdr::Repository).to receive(:lock).and_return('v1')
        allow(Sdr::Repository).to receive(:find_solr).and_raise(Sdr::Repository::NotFoundResponse)
      end

      it 'prepends the druid: prefix before looking up the object' do
        get "/objects/#{druid}"

        expect(Sdr::Repository).to have_received(:lock).with(druid: 'druid:bc123df4567')
      end
    end

    context 'when the druid is malformed' do
      it 'renders a 404 without looking up the object' do
        get '/objects/druid%5B%5D=x'

        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe 'Admin permissions navigation' do
    include_context 'with show page object client'

    let(:user) { create(:user, groups: [AuthenticationHelpers::ADMIN_GROUP]) }
    let(:object_type) { 'collection' }
    let(:cocina_object) { build(:collection_with_metadata, id: druid) }
    let(:rendered_page) { Capybara.string(response.body).find('.object-show') }

    before do
      create(:permission, :read_unrestricted, workgroup: 'sdr:argo-access')
      allow(Sdr::Repository).to receive_messages(
        find: cocina_object,
        find_solr: {
          Search::Fields::ID => druid, Search::Fields::OBJECT_TYPES => [object_type],
          Search::Fields::TITLE => 'My object',
          Search::Fields::AGREEMENT_DRUID => 'druid:df456gh7890', Search::Fields::AGREEMENT_TITLE => 'Agreement'
        }
      )
      allow(Sdr::WorkflowService).to receive(:published?).and_return(false)
      sign_in(user)
    end

    it 'offers Manage permissions in the Admin button list for a collection' do
      get object_path(druid)
      expect(response).to have_http_status(:ok)
      expect(rendered_page).to have_css('h2', text: 'Admin')
      expect(rendered_page).to have_button('Manage permissions')
      expect(rendered_page).to have_css("form[action='#{admin_object_permissions_path(druid)}'][method='get']")
    end

    context 'when the object is an APO' do
      let(:object_type) { 'APO' }
      let(:cocina_object) { build(:admin_policy_with_metadata, id: druid) }

      it 'offers Manage permissions' do
        get object_path(druid)
        expect(rendered_page).to have_button('Manage permissions')
        expect(rendered_page).to have_css("form[action='#{admin_object_permissions_path(druid)}'][method='get']")
      end
    end

    context 'when the object is an item' do
      let(:object_type) { 'item' }
      let(:cocina_object) { build(:dro_with_metadata, id: druid) }

      it 'omits the Admin button list' do
        get object_path(druid)
        expect(rendered_page).to have_no_css('h2', text: 'Admin')
        expect(rendered_page).to have_no_button('Manage permissions')
      end
    end

    context 'when the user is not an admin' do
      let(:user) { create(:user) }

      it 'omits the Admin button list' do
        get object_path(druid)
        expect(rendered_page).to have_no_css('h2', text: 'Admin')
        expect(rendered_page).to have_no_button('Manage permissions')
      end
    end
  end

  describe 'GET /objects/:druid/track' do
    it 'redirects to the clean object show page' do
      get "/objects/#{druid}/track", params: { search_position: 3 }

      expect(response).to redirect_to("/objects/#{druid}")
      expect(response).to have_http_status(:see_other)
    end

    it 'records the search_position in the last_search cookie' do
      get "/objects/#{druid}/track", params: { search_position: 3 }

      expect(response.cookies['last_search']).to be_present
    end

    context 'without a search_position param' do
      it 'redirects without setting a cookie' do
        get "/objects/#{druid}/track"

        expect(response).to redirect_to("/objects/#{druid}")
        expect(response.cookies['last_search']).to be_nil
      end
    end

    context 'when the request is a Turbo prefetch' do
      it 'redirects without recording the search_position' do
        get "/objects/#{druid}/track", params: { search_position: 3 }, headers: { 'X-Sec-Purpose' => 'prefetch' }

        expect(response).to redirect_to("/objects/#{druid}")
        expect(response.cookies['last_search']).to be_nil
      end
    end

    context 'when the druid is malformed' do
      it 'renders a 404 without redirecting' do
        get '/objects/druid%5B%5D=x/track'

        expect(response).to have_http_status(:not_found)
      end
    end
  end
end
