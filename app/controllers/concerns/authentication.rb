# frozen_string_literal: true

# Concern for handling authentication.
# Note that this concern is based on the generated code.
module Authentication
  extend ActiveSupport::Concern

  # Apache is configured so that:
  # - /webauth/login requires a shibboleth authenticated user. Thus, redirecting a user to it triggers login.
  # - /Shibboleth.sso/Logout logs the user out of shibboleth.
  # - Other pages do not require authentication.
  # - It provides the following request headers:
  #  - X-Remote-User
  #  - X-Groups
  #  - X-Person-Formal-Name (full name)

  MAX_URL_SIZE = ActionDispatch::Cookies::MAX_COOKIE_SIZE / 2
  SHIBBOLETH_LOGOUT_PATH = '/Shibboleth.sso/Logout'

  USER_GROUPS_HEADER = 'X-Groups'
  FULL_NAME_HEADER = 'X-Person-Formal-Name'
  REMOTE_USER_HEADER = 'X-Remote-User'

  included do
    # authentication will be called before require_authentication.
    # It will authenticate the user if there is a user.
    # This will be called for all controller actions.
    # require_authentication will also be called for all controller actions,
    # unless skipped with allow_unauthenticated_access.
    before_action :authentication, :require_authentication
    helper_method :authenticated?, :current_user
  end

  class_methods do
    def allow_unauthenticated_access(**)
      skip_before_action :require_authentication, **
    end
  end

  def current_user
    Current.user
  end

  private

  def remote_user
    return ENV.fetch('EMAIL') if Rails.env.development?

    request.headers[REMOTE_USER_HEADER]
  end

  def authenticated?
    remote_user.present?
  end

  def authentication
    # This adds the cookie in development/test so that action cable can authenticate.
    start_new_session if start_new_session?
    resume_session
  end

  def start_new_session?
    return true if Rails.env.development?

    Rails.env.test? && user_attrs[:email_address].present?
  end

  def require_authentication
    resume_session || request_authentication
  end

  def resume_session
    Current.user ||= User.find_by(email_address: remote_user)
  end

  def request_authentication
    # Always check that we have enough space in the cookie to store the full return URL.
    #
    # This situation typically occurs when we are scanned for vulnerabilities and a
    # CRLF Injection attack is attempted, see https://www.geeksforgeeks.org/crlf-injection-attack/
    session[:return_to_after_authenticating] = request.url if request.url.size < MAX_URL_SIZE
    redirect_to main_app.login_path
  end

  def after_authentication_url
    session.delete(:return_to_after_authenticating) || root_url
  end

  def start_new_session
    # Create or update a user based on the headers provided by Apache.
    results = User.upsert(user_attrs, unique_by: :email_address) # rubocop:disable Rails/SkipsModelValidations
    # This cookie will be used to authenticate Action Cable connections.
    cookies.signed.permanent[:user_id] = { value: results.rows[0][0], httponly: true, same_site: :lax }
  end

  def user_attrs # rubocop:disable Metrics/AbcSize
    # Provided in cookies for test. Provided in ENV for development.
    {
      email_address: request.headers[REMOTE_USER_HEADER] ||
        request.cookies['test_shibboleth_remote_user'] ||
        ENV.fetch('EMAIL', nil),
      name: request.headers[FULL_NAME_HEADER] ||
        request.cookies['test_shibboleth_full_name'] ||
        ENV.fetch('NAME', nil),
      groups: (request.headers[USER_GROUPS_HEADER] ||
        request.cookies['test_shibboleth_groups'] ||
        ENV.fetch('USER_GROUPS', '')).split(';')
    }
  end

  def terminate_session
    cookies.delete(:user_id)
  end
end
