# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'MissionControl jobs' do
  let(:user) { create(:user) }

  before { sign_in(user) }

  it 'prevents access' do
    get mission_control_jobs_path

    expect(response).to have_http_status(:found)
    expect(response).to redirect_to('/')
  end

  describe 'GET /jobs' do
    context 'with admin user' do
      let(:user) { create(:user, :admin) }

      it 'renders the mission control interface' do
        get mission_control_jobs_path

        expect(response).to have_http_status(:ok)
        expect(response.body).to include('Mission control - Queues')
      end
    end
  end
end
