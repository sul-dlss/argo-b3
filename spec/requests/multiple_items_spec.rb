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
  end
end
