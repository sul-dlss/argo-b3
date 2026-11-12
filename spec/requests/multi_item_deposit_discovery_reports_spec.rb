# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Multi-item deposit discovery reports' do
  let(:user) { create(:user, groups: ['sdr:test-workgroup']) }
  let(:multi_item_deposit_action) do
    create(:multi_item_deposit_action, user: owner, discovery_completed_at: Time.current)
  end

  before do
    sign_in(user)
    create(:item_deposit_action, multi_item_deposit_action:, druid: 'druid:bc123df4567', path: 'folder1',
                                 manifest_line_number: 2, content_type: 'image', discovery_errors: ['Object not found'])
  end

  context 'when the multi-item deposit action belongs to the user' do
    let(:owner) { user }

    it 'downloads the report of the results of checking the manifest' do
      get multi_item_deposit_action_discovery_report_path(multi_item_deposit_action)

      expect(response).to have_http_status(:ok)
      expect(response.media_type).to eq('text/csv')
      expect(response.headers['Content-Disposition'])
        .to include("attachment; filename=\"multi_item_deposit_#{multi_item_deposit_action.id}_discovery_report.csv\"")
      expect(response.body.lines.second).to eq("2,bc123df4567,folder1,image,Object not found,\n")
    end
  end

  context 'when checking the manifest has not completed' do
    let(:owner) { user }
    let(:multi_item_deposit_action) do
      create(:multi_item_deposit_action, user: owner, discovery_state: 'discovering', discovery_completed_at: nil)
    end

    it 'redirects to the Multi-Item Deposit' do
      get multi_item_deposit_action_discovery_report_path(multi_item_deposit_action)

      expect(response).to redirect_to(edit_multi_item_deposit_action_path(multi_item_deposit_action))
    end
  end

  context 'when the multi-item deposit action belongs to another user' do
    let(:owner) { create(:user) }

    it 'denies access' do
      get multi_item_deposit_action_discovery_report_path(multi_item_deposit_action)

      expect(response).to redirect_to(root_path)
    end
  end
end
