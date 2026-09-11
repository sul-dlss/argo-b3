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
end
