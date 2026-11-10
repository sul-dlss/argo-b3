# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Skip link' do
  let(:user) { create(:user) }

  before do
    sign_in(user)
  end

  it 'moves focus to the main landmark' do
    visit root_path

    page.send_keys(:tab)
    expect(page).to have_css('a:focus', text: 'Skip to main content')

    page.send_keys(:enter)
    expect(page).to have_css('main#main-container:focus')
  end
end
