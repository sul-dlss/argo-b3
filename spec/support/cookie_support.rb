# frozen_string_literal: true

def set_last_search_cookie(search_form: SearchForm.new(query: 'test', page: 5), total_results: 10) # rubocop:disable Metrics/AbcSize
  visit root_path
  signed_value = Rails.application
                      .message_verifier(Rails.application.config.action_dispatch.signed_cookie_salt)
                      .generate({
                                  form: search_form.attributes, total_results:
                                })
  page.driver.browser.manage.add_cookie(
    name: :last_search,
    value: signed_value,
    path: '/',
    domain: Capybara.current_session.server.host
  )
end
