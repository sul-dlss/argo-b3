# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Dashboard' do
  let(:user) { create(:user) }

  before do
    sign_in(user)
  end

  it 'renders the dashboard' do
    get root_path

    expect(response).to have_http_status(:ok)
  end
end
