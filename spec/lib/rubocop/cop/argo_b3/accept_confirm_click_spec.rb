# frozen_string_literal: true

require 'rubocop'
require 'rubocop/rspec/support'
require_relative '../../../../../lib/rubocop/cop/argo_b3/accept_confirm_click'

RSpec.describe RuboCop::Cop::ArgoB3::AcceptConfirmClick, :config do
  it 'registers an offense for click_link inside accept_confirm' do
    expect_offense(<<~RUBY)
      accept_confirm(/Discard/) do
        click_link 'Discard draft'
        ^^^^^^^^^^^^^^^^^^^^^^^^^^ Use `click_and_accept_confirm(message, find_link(...))` rather than clicking inside `accept_confirm`.
      end
    RUBY
  end

  it 'registers an offense for click_button inside an accept_confirm brace block' do
    expect_offense(<<~RUBY)
      accept_confirm('Delete?') { click_button 'Delete' }
                                  ^^^^^^^^^^^^^^^^^^^^^ Use `click_and_accept_confirm(message, find_link(...))` rather than clicking inside `accept_confirm`.
    RUBY
  end

  it 'does not register an offense for click_and_accept_confirm' do
    expect_no_offenses(<<~RUBY)
      click_and_accept_confirm('Delete?', find_button('Delete'))
    RUBY
  end

  it 'does not register an offense for clicks outside accept_confirm' do
    expect_no_offenses(<<~RUBY)
      within('#files') { click_button 'Delete' }
    RUBY
  end
end
