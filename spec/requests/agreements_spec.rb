# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Agreements' do
  let(:user) { create(:user, groups: [workgroup]) }
  let(:workgroup) { 'sdr:test-workgroup' }

  before do
    create(:permission, :edit, workgroup:, target_druid: Settings.ur_apo_druid)
    sign_in(user)
  end

  describe 'new' do
    it 'renders the agreement form' do
      get '/agreements/new'

      expect(response).to have_http_status(:ok)
      page = Capybara.string(response.body)
      expect(page).to have_css('h1', text: 'Register an agreement')
      expect(page).to have_field('agreement[title]')
      expect(page).to have_field('agreement[source_id]')
      expect(page).to have_button('Register and add files')
      expect(page).to have_button('Register only')
      expect(page).to have_no_field('agreement[content_type]')
    end
  end

  describe 'create' do
    let(:registered_cocina_object) { build(:agreement_with_metadata, id: 'druid:xz987wv6543') }

    before do
      allow(Sdr::Repository).to receive_messages(register: registered_cocina_object, source_id_exists?: false)
    end

    context 'when registering only' do
      it 'registers a dark agreement governed by the ur APO' do
        # The content type, governing APO, and access cannot be set by the user.
        post '/agreements', params: { commit: 'draft',
                                      agreement: { title: 'My Agreement', source_id: 'sul:agreement-1',
                                                   apo_druid: 'druid:dd111dd1111', content_type: 'book',
                                                   access_view: 'world',
                                                   other_tags_attributes: { '0' => { tag: 'Some : Tag' } } } }

        expect(response).to redirect_to('/objects/druid:xz987wv6543')
        expect(flash[:toast]).to eq('Agreement registered.')
        expect(Sdr::Repository).to have_received(:register) do |args|
          request_cocina_object = args[:request_cocina_object]
          expect(request_cocina_object.type).to eq(Cocina::Models::ObjectType.agreement)
          expect(request_cocina_object.description.title.first.value).to eq('My Agreement')
          expect(request_cocina_object.administrative.hasAdminPolicy).to eq(Settings.ur_apo_druid)
          expect(request_cocina_object.access.to_h).to include(view: 'dark', download: 'none')
          expect(args[:tags]).to eq(['Some : Tag'])
        end
      end
    end

    context 'when registering and adding files' do
      it 'redirects to manage files' do
        post '/agreements', params: { commit: 'add_files',
                                      agreement: { title: 'My Agreement', source_id: 'sul:agreement-1' } }

        expect(response).to redirect_to('/contents/druid:xz987wv6543/edit')
      end
    end

    context 'when invalid' do
      it 'renders the form' do
        post '/agreements', params: { agreement: { source_id: 'sul:agreement-1' } }

        expect(response).to have_http_status(:unprocessable_content)
        expect(Sdr::Repository).not_to have_received(:register)
      end
    end
  end

  context 'when the user does not have edit permission for the ur APO' do
    let(:user) { create(:user, groups: ['sdr:other-workgroup']) }

    before do
      allow(Sdr::Repository).to receive(:register)
    end

    it 'denies access to the new agreement form' do
      get '/agreements/new'

      expect(response).to redirect_to(root_path)
      expect(flash[:warning]).to eq('You are not authorized to perform the requested action.')
    end

    it 'denies creating an agreement' do
      post '/agreements', params: { agreement: { title: 'My Agreement', source_id: 'sul:agreement-1' } }

      expect(response).to redirect_to(root_path)
      expect(Sdr::Repository).not_to have_received(:register)
    end
  end
end
