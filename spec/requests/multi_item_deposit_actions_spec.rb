# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Multi-item deposit actions' do
  let(:workgroup) { 'sdr:test-workgroup' }
  let(:user) { create(:user, groups: [workgroup]) }
  let(:rendered_page) { Capybara.string(response.body) }

  before do
    sign_in(user)
  end

  describe 'create' do
    context 'when the user belongs to a workgroup with edit permission' do
      before do
        create(:permission, :edit, workgroup:, target_druid: 'druid:bc123df4567')
      end

      it 'creates a multi-item deposit action and redirects to the edit page' do
        expect { post multi_item_deposit_actions_path }.to change(MultiItemDepositAction, :count).by(1)

        multi_item_deposit_action = MultiItemDepositAction.last
        expect(multi_item_deposit_action.user).to eq(user)
        expect(multi_item_deposit_action).to be_step_discovery
        expect(response).to redirect_to(edit_multi_item_deposit_action_path(multi_item_deposit_action))
      end
    end

    context 'when the user is an admin' do
      let(:user) { create(:user, :admin) }

      it 'creates a multi-item deposit action' do
        expect { post multi_item_deposit_actions_path }.to change(MultiItemDepositAction, :count).by(1)
      end
    end

    context 'when the user does not belong to a workgroup with edit permission' do
      it 'denies access' do
        expect { post multi_item_deposit_actions_path }.not_to change(MultiItemDepositAction, :count)

        expect(response).to redirect_to(root_path)
      end
    end
  end

  describe 'edit' do
    let(:multi_item_deposit_action) { create(:multi_item_deposit_action, user: owner, description: 'My deposit') }

    context 'when the multi-item deposit action belongs to the user' do
      let(:owner) { user }

      it 'renders the edit page' do
        get edit_multi_item_deposit_action_path(multi_item_deposit_action)

        expect(response).to have_http_status(:ok)
        expect(rendered_page).to have_css('h1', text: 'Multi-item deposit')
        expect(rendered_page).to have_text('My deposit')
      end
    end

    context 'when the multi-item deposit action belongs to another user' do
      let(:owner) { create(:user) }

      it 'denies access' do
        get edit_multi_item_deposit_action_path(multi_item_deposit_action)

        expect(response).to redirect_to(root_path)
      end
    end
  end
end
