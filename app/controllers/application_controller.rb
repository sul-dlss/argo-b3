# frozen_string_literal: true

class ApplicationController < ActionController::Base
  include Authentication

  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  # Adds an after_action callback to verify that `authorize!` has been called.
  # See https://actionpolicy.evilmartians.io/#/rails?id=verify_authorized-hooks for how to skip.
  verify_authorized

  rescue_from ActionPolicy::Unauthorized, with: :deny_access
  rescue_from ActiveSupport::MessageVerifier::InvalidSignature, with: :forbidden_access

  private

  def deny_access
    flash[:warning] = helpers.t('errors.not_authorized')
    redirect_to main_app.root_path
  end

  def forbidden_access
    render plain: 'Forbidden', status: :forbidden
  end

  # Sets @last_search_form and @total_results from the last search cookie.
  # Note that this deliberately does not assign @search_form: the last search is not the current
  # search, and conflating them would let a stale cookie silently override the current search.
  def set_from_last_search_cookie
    return if cookies.signed[:last_search].blank?

    form_params, @total_results = cookies.signed[:last_search]&.values_at('form', 'total_results')
    @last_search_form = ResultsSearchForm.new(form_params)
  end
end
