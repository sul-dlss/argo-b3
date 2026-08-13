# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Manage files' do
  let(:druid) { 'druid:bc123df4567' }
  let(:title) { 'My title' }

  let(:cocina_object) { build(:dro_with_metadata, id: druid) }

  before do
    sign_in(create(:user))

    allow(Sdr::Repository).to receive_messages(find: cocina_object,
                                               find_solr: build(:solr_item, druid:, title:))
  end

  it 'displays the object title and all tabs' do
    visit "/contents/#{druid}/edit"

    expect(page).to have_css('p', text: title)

    expect(page).to have_css('.nav-link', text: 'Add files')
    expect(page).to have_css('.nav-link', text: 'Manage files')
    expect(page).to have_css('.nav-link', text: 'Deposit')
  end
end
