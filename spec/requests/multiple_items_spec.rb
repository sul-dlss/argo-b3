# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Multiple items' do
  let(:workgroup) { 'sdr:test-workgroup' }
  let(:user) { create(:user, groups: [workgroup]) }

  before do
    sign_in(user)
  end

  context 'when the user belongs to a workgroup with edit permission' do
    before do
      create(:permission, :edit, workgroup:, target_druid: 'druid:bc123df4567')
    end

    it 'renders the new page' do
      get new_multiple_item_path

      expect(response).to have_http_status(:ok)
    end
  end

  context 'when the user does not belong to a workgroup with edit permission' do
    it 'denies access' do
      get new_multiple_item_path

      expect(response).to redirect_to(root_path)
    end
  end

  describe 'clearing the items' do
    before do
      create(:permission, :edit, workgroup:, target_druid: 'druid:bc123df4567')
      allow(Searchers::AdminPolicyList).to receive(:call).and_return([['My APO', 'druid:hv992ry2431']])
      allow(Searchers::CollectionListByDruid).to receive(:call)
        .and_return([['Art History Slides', 'druid:bc123df4567']])
    end

    it 'renders the selected collections, labeling those not found with the bare druid' do
      post multiple_items_path, params: {
        commit: MultipleItemsController::CLEAR_VALUE,
        items_registration: { collection_druids: ['', 'druid:bc123df4567', 'druid:xz987wv6543'] }
      }

      expect(response).to have_http_status(:unprocessable_content)
      page = Capybara.string(response.body)
      expect(page).to have_select('Collections', visible: :all, selected: ['Art History Slides', 'xz987wv6543'])
      expect(Searchers::CollectionListByDruid).to have_received(:call)
        .with(druids: %w[druid:bc123df4567 druid:xz987wv6543])
    end
  end

  describe 'showing a form validation action' do
    let(:form_validation_action) do
      FormValidationAction.create!(user: form_validation_action_user, form: ItemsRegistrationForm.new,
                                   status: 'queued')
    end

    before do
      allow(Searchers::AdminPolicyList).to receive(:call).and_return([])
    end

    context 'when the form validation action belongs to the user' do
      let(:form_validation_action_user) { user }

      it 'renders the show page' do
        get multiple_item_path(form_validation_action)

        expect(response).to have_http_status(:ok)
      end
    end

    context 'when the form validation action belongs to another user' do
      let(:form_validation_action_user) { create(:user) }

      it 'denies access' do
        get multiple_item_path(form_validation_action)

        expect(response).to be_unauthorized
      end
    end

    context 'when the form validation action is invalid' do
      let(:form_validation_action) do
        FormValidationAction.create!(user:, form: ItemsRegistrationForm.new(collection_druids: ['druid:bc123df4567']),
                                     status: 'invalid')
      end

      before do
        allow(Searchers::CollectionListByDruid).to receive(:call)
          .and_return([['Art History Slides', 'druid:bc123df4567']])
      end

      it 'renders the selected collections' do
        get multiple_item_path(form_validation_action)

        expect(response).to have_http_status(:unprocessable_content)
        page = Capybara.string(response.body)
        expect(page).to have_select('Collections', visible: :all, selected: ['Art History Slides'])
        expect(Searchers::CollectionListByDruid).to have_received(:call).with(druids: ['druid:bc123df4567'])
      end
    end
  end
end
