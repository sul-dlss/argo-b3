# frozen_string_literal: true

def signed_last_search_cookie(search_form: ResultsSearchForm.new(query: 'test', page: 5), total_results: 10,
                              search_position: nil, search_position_druid: nil)
  Rails.application
       .message_verifier(Rails.application.config.action_dispatch.signed_cookie_salt)
       .generate({ form: search_form.attributes, total_results:, search_position:, search_position_druid: }
                  .compact)
end

def set_last_search_cookie(search_form: ResultsSearchForm.new(query: 'test', page: 5), total_results: 10,
                           search_position: nil, search_position_druid: nil)
  visit root_path
  signed_value = signed_last_search_cookie(search_form:, total_results:, search_position:, search_position_druid:)
  page.driver.browser.manage.add_cookie(
    name: :last_search,
    value: signed_value,
    path: '/',
    domain: Capybara.current_session.server.host
  )
end
