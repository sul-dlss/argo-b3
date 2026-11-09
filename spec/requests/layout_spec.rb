# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Application layout' do
  let(:user) { create(:user) }
  let(:rendered_page) { Capybara.string(response.body) }

  before do
    sign_in(user)
  end

  it 'sets the document language' do
    get root_path

    expect(rendered_page).to have_css('html[lang="en"]', visible: :all)
  end

  it 'puts the page content in a single main landmark, outside the header, search bar, and footer' do
    get root_path

    expect(rendered_page).to have_css('main', count: 1)
    expect(rendered_page).to have_css('main#main-container h1', text: 'Argo dashboard')
    expect(rendered_page).to have_no_css('main header, main .search-bar, main footer')
    expect(rendered_page).to have_css('header').and have_css('.search-bar').and have_css('footer')
  end

  it 'makes the skip link to the main landmark the first focusable element' do
    get root_path

    first_focusable = rendered_page.first('a[href], button, input, select, textarea, [tabindex]:not([tabindex="-1"])',
                                          visible: :all)
    expect(first_focusable).to have_text('Skip to main content')
    expect(first_focusable[:href]).to eq('#main-container')
  end
end
