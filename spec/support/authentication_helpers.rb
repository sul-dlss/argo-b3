# frozen_string_literal: true

# Helpers to assist with authentication.
module AuthenticationHelpers
  ADMIN_GROUP = 'sdr:argo_administrators'

  # Used by login and logout tests.
  def authentication_headers_for(user)
    {
      Authentication::REMOTE_USER_HEADER => user.email_address,
      Authentication::FULL_NAME_HEADER => user.name,
      Authentication::USER_GROUPS_HEADER => user.groups.join(';')
    }
  end

  def sign_in(user, example: RSpec.current_example)
    if example.metadata[:type] == :system
      visit test_login_path(id: user.id)
    else
      get test_login_path(id: user.id)
    end
  end

  def request_sign_in(user)
    visit test_login_path(id: user.id)
  end

  RSpec.configure do |config|
    config.include AuthenticationHelpers, type: :system
    config.include AuthenticationHelpers, type: :request

    config.before do
      create(:permission, :admin, workgroup: ADMIN_GROUP)
    end
  end
end
