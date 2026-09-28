# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Edit::FileSetComponent, type: :component do
  let(:component) { described_class.new(content_file_set_form:, counter: 1, content_token: 'abc123') }

  let(:content_file_set_form) { ContentFileSetForm.from_model(content_file_set) }
  let(:content_file_set) { create(:content_file_set, file_set_type: 'page', label: 'Page 2') }

  let(:field_prefix) { 'content_file_set[content_files_attributes][0]' }
  let!(:content_file) do
    create(:content_file, content_file_set:, use: 'transcription',
                          content_file_binary: create(:content_file_binary, content: content_file_set.content,
                                                                            mime_type: 'image/tiff'))
  end

  it 'renders a required resource type select with the current type selected' do
    render_inline(component)

    expect(page).to have_css('label', text: 'Resource type') { |label| label.has_css?('span.required') }
    expect(page).to have_select('content_file_set[file_set_type]',
                                selected: 'page',
                                options: %w[audio attachment document file image media object page preview 3d thumb
                                            video])
  end

  it 'renders each file with a role field' do
    render_inline(component)

    expect(page).to have_css('.card .card-title .h4', text: 'image1.tif')
    expect(page).to have_field('Role', with: 'transcription')
    expect(page).to have_field('MIME type', with: 'image/tiff')
    expect(page).to have_css('label', text: 'MIME type') { |label| label.has_css?('span.required') }
    expect(page).to have_field("#{field_prefix}[id]", with: content_file.id, type: :hidden)
  end
end
