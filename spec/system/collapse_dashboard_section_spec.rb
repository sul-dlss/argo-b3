# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Collapse a dashboard section' do
  let(:user) { create(:user) }

  before do
    create(:pinned_tag, user:, tag: 'Project : Maps')

    sign_in(user)
  end

  it 'collapses and expands a section, keeping it collapsed when the dashboard is morphed' do
    visit root_path

    expect(page).to have_text('No objects have been viewed.')
    toggle = find_button('Recently viewed')
    expect(toggle['aria-expanded']).to eq('true')

    toggle.click
    expect(page).to have_no_text('No objects have been viewed.')
    expect(toggle['aria-expanded']).to eq('false')

    # Unpinning redirects back to the dashboard, which morphs the page.
    within('table[aria-label="Pinned tags"]') do
      click_button('Unpin')
    end
    expect(page).to have_text('No tags have been pinned.')
    expect(page).to have_no_text('No objects have been viewed.')
    expect(find_button('Recently viewed')['aria-expanded']).to eq('false')

    find_button('Recently viewed').click
    expect(page).to have_text('No objects have been viewed.')
    expect(find_button('Recently viewed')['aria-expanded']).to eq('true')
  end
end
