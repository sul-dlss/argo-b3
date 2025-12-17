# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Login' do
  describe 'GET /webauth/login' do
    let(:jar) { ActionDispatch::Cookies::CookieJar.build(request, cookies.to_hash) }

    context 'when a user does not exist' do
      let(:user) { build(:user) }

      it 'creates a user and sets a cookie' do
        expect do
          get '/webauth/login', headers: authentication_headers_for(user)
        end.to change(User, :count).by(1)

        new_user = User.find_by(email_address: user.email_address)
        expect(new_user.name).to eq(user.name)
        expect(new_user.groups).to eq(user.groups)

        expect(response).to redirect_to(root_path)
        expect(jar.signed[:user_id]).to eq(new_user.id)
      end
    end

    context 'when a user does exist' do
      let(:user) { create(:user) }
      let(:headers) do
        {
          Authentication::REMOTE_USER_HEADER => user.email_address,
          Authentication::FULL_NAME_HEADER => 'New name',
          Authentication::USER_GROUPS_HEADER => 'sdr:argo-access;sdr:admin'
        }
      end

      it 'updates the user and sets a cookie' do
        expect { get '/webauth/login', headers: }
          .to change { user.reload.name }
          .to('New name')
          .and change(user, :groups)
          .to(['sdr:argo-access', 'sdr:admin'])

        expect(response).to redirect_to(root_path)
        expect(jar.signed[:user_id]).to eq(user.id)
      end
    end
  end
end
