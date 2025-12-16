class AuthenticationController < ApplicationController
  def login
    Rails.logger.info("HEADERS: #{request.headers.to_h.inspect}")
    # Placeholder login action
    render plain: 'Login action'
  end
end
