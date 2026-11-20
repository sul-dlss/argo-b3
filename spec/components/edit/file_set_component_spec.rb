# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Edit::FileSetComponent, type: :component do
  let(:component) { described_class.new(content_file_set_form:, counter: 1, content_token: 'abc123') }

  let(:content_file_set_form) { ContentFileSetForm.from_model(content_file_set) }
  let(:content_file_set) { create(:content_file_set, file_set_type: 'page', label: 'Page 2') }

  let(:field_prefix) { 'content_file_set[content_files_attributes][0]' }
  let!(:content_file) do
    create(:content_file, content_file_set:, use: 'transcription', language_tag: 'en',
                          content_file_binary: create(:content_file_binary, content: content_file_set.content,
                                                                            mime_type: 'image/tiff'))
  end

  it 'renders the resource heading' do
    render_inline(component)

    expect(page).to have_css('.card.file-set-card .card-title h4.h3', exact_text: 'Resource 2')
  end

  it 'renders a required resource type select with the current type selected' do
    render_inline(component)

    expect(page).to have_css('.card-title label', text: 'Resource type') { |label| label.has_css?('span.required') }
    expect(page).to have_select('Resource type',
                                selected: 'page',
                                options: %w[audio document file image media object page preview 3d video])
  end

  it 'renders the label field in the header' do
    render_inline(component)

    expect(page).to have_css('.card-title label', text: 'Label')
    expect(page).to have_field('Label', with: 'Page 2')
  end

  it 'renders a files table with a column for each field' do
    render_inline(component)

    expect(page).to have_css('table[aria-label="Files for resource 2"]')
    expect(page).to have_css('thead th', count: 11)
    expect(page.all('thead th').map { |header| header.text.strip.delete('*').strip })
      .to eq(['File name', 'MIME type', 'View', 'Download', 'Location', 'Publish', 'Preserve', 'Role',
              'Accessible', 'Language', 'Actions'])
  end

  it 'renders a row for each file, with inputs labelled by the filepath' do
    render_inline(component)

    expect(page).to have_css('[data-controller="content-files"] tbody tr[data-content-files-target="row"]' \
                             '[data-controller="access-rights"]', count: 1)
    expect(page).to have_css('tbody tr td:first-child', text: 'image1.tif')
    expect(page).to have_select('MIME type for image1.tif', selected: 'image/tiff')
    expect(page).to have_css('label', text: 'MIME type for image1.tif') { |label| label.has_css?('span.required') }
    expect(page).to have_css('select[data-controller="creatable-select"]', count: 3)
    expect(page).to have_select('View access for image1.tif', selected: 'World',
                                                              options: ['World', 'Dark', 'Stanford', 'Location Based'])
    expect(page).to have_select('Download access for image1.tif', selected: 'World')
    expect(page).to have_select('Location for image1.tif')
    expect(page).to have_checked_field('Publish image1.tif')
    expect(page).to have_checked_field('Preserve image1.tif')
    expect(page).to have_select('Role for image1.tif', selected: 'transcription')
    expect(page).to have_unchecked_field('image1.tif corrected for accessibility')
    expect(page).to have_select('Language for image1.tif', selected: 'en')
    expect(page).to have_field("#{field_prefix}[id]", with: content_file.id, type: :hidden)
    expect(page).to have_field("#{field_prefix}[_destroy]", with: 'false', type: :hidden)
    expect(page).to have_css('button[data-action="content-files#remove"] .bi-trash')
    expect(page).to have_button('Remove image1.tif')
  end

  context 'when a file is preserved but not published' do
    before { content_file.update!(publish: false, shelve: false, preserve: true) }

    it 'checks only preserve' do
      render_inline(component)

      expect(page).to have_unchecked_field('Publish image1.tif')
      expect(page).to have_checked_field('Preserve image1.tif')
    end
  end

  context 'when a file is neither published nor preserved' do
    before do
      content_file_set_form.content_files.first.assign_attributes(publish: false, preserve: false)
      content_file_set_form.valid?
    end

    it 'renders the error in the file row' do
      render_inline(component)

      expect(page).to have_css('tbody tr .invalid-feedback', text: 'Select publish, preserve, or both.')
      expect(page).to have_field('Publish image1.tif', unchecked: true) { |field| field['aria-invalid'] == 'true' }
    end
  end

  it 'renders a save button that is disabled while other actions are in progress' do
    render_inline(component)

    expect(page).to have_css('button[data-disable-actions-target="disableable"]', text: 'Save')
  end

  it 'renders Cancel before Save in the footer' do
    render_inline(component)

    expect(page).to have_css('.d-flex > a.btn.btn-link:first-child', text: 'Cancel')
    expect(page).to have_css('.d-flex > a + button', text: 'Save')
  end

  it 'renders a hidden note for when every file is removed in an alert region' do
    render_inline(component)

    expect(page).to have_css('[role="alert"] p[data-content-files-target="allRemovedNote"]',
                             text: 'Saving will delete this resource.', visible: :hidden)
  end

  it 'renders the corrected for accessibility checkbox' do
    content_file.update!(corrected_for_accessibility: true)

    render_inline(component)

    expect(page).to have_checked_field('image1.tif corrected for accessibility')
  end
end
