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
          expect(request_cocina_object.administrative.hasAdminPolicy).to eq(Settings.uber_apo_druid)
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

  context 'when the user is not an admin' do
    let(:user) { create(:user) }

    before do
      allow(Sdr::Repository).to receive(:register)
    end

    it 'denies access to the new APO form' do
      get '/apos/new'

      expect(response).to redirect_to(root_path)
      expect(flash[:warning]).to eq('You are not authorized to perform the requested action.')
    end

    it 'denies creating an APO' do
      post '/apos', params: { apo: { title: 'My APO', agreement_druid: 'druid:bc123df4567' } }

      expect(response).to redirect_to(root_path)
      expect(Sdr::Repository).not_to have_received(:register)
    end
  end
end
