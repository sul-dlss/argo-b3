# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Reports' do
  before do
    sign_in(create(:user, :reader))
  end

  describe 'show' do
    it 'renders one h1 and a level-2 heading for each field section' do
      get report_path

      expect(response).to have_http_status(:ok)
      page = Capybara.string(response.body)
      expect(page).to have_css('h1', count: 1)
      expect(page).to have_css('h1', text: 'Custom report')
      expect(page.all('h2').map { |heading| heading.text.strip })
        .to eq(['Frequently used', 'Citation', 'History', 'Identifiers', 'Content'])
    end

    it 'renders the source of items chooser' do
      get report_path

      page = Capybara.string(response.body)
      expect(page).to have_css('fieldset legend', exact_text: 'Select source of items for report', normalize_ws: true)
      expect(page).to have_field('From last search', type: 'radio', disabled: true)
      expect(page).to have_field('From druid list', type: 'radio', checked: true)
      expect(page).to have_field('Enter druid list', type: 'textarea')
    end
  end
end
