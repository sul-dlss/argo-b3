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

  it 'displays the object title and all tabs, and uploads a file' do
    visit "/contents/#{druid}/edit"

    expect(page).to have_css('p', text: title)

    expect(page).to have_css('.nav-link', text: 'Add files')
    expect(page).to have_css('.nav-link', text: 'Manage files')
    expect(page).to have_css('.nav-link', text: 'Deposit')

    attach_file(nil, Rails.root.join('spec/fixtures/files/dropzone_upload.txt'), make_visible: true)

    click_on 'Manage files'

    expect(page).to have_css('li', text: 'dropzone_upload.txt')

    content = Content.find_by!(druid:)
    content_file_set = content.content_file_sets.sole
    expect(content_file_set).to have_attributes(file_set_type: 'object')

    content_file = content_file_set.content_files.sole
    content_file_binary = content_file.content_file_binary
    expect(content_file_binary).to have_attributes(filepath: 'dropzone_upload.txt', file_location: 'attached')
    expect(content_file_binary.file).to be_attached
    expect(content_file_binary.file.filename.to_s).to eq('dropzone_upload.txt')
  end
end
