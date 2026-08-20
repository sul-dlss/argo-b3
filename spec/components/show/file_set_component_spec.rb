# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Show::FileSetComponent, type: :component do
  let(:component) { described_class.new(content_file_set:, content_file_set_counter: 1) }

  let(:content_file_set) do
    instance_double(ContentFileSet, file_set_type: 'file', label: 'Resource 2', content_files: [content_file])
  end

  let(:content_file) do
    instance_double(ContentFile,
                    filepath: 'image1.tif',
                    size: 1024,
                    mime_type: 'image/tiff',
                    view: 'world',
                    download: 'stanford',
                    location: 'spec',
                    publish: true,
                    preserve: true,
                    use: 'transcription',
                    language_tag: 'en')
  end

  it 'renders the resource heading and label' do
    render_inline(component)

    expect(page).to have_css('.card-title', text: 'Resource (2): file')
    expect(page).to have_css('.card-title', text: 'Label: Resource 2')
  end

  it 'renders a row for each content file' do
    render_inline(component)

    expect(page).to have_css("table[aria-label='Files for resource 2']")
    expect(page).to have_css('th', text: 'File name')
    expect(page).to have_css('td', text: 'image1.tif')
    expect(page).to have_css('td', text: 'Size: 1 KB; Type: image/tiff')
    expect(page).to have_css('td', text: 'World')
    expect(page).to have_css('td', text: 'Stanford')
    expect(page).to have_css('td', text: 'Special collections')
    expect(page).to have_css('td', text: 'Transcription')
    expect(page).to have_css('td', text: 'en')
  end

  it 'shows checkmarks for publish and preserve' do
    render_inline(component)

    expect(page).to have_css('td', text: '✔', count: 2)
  end

  context 'when the content file has no location' do
    let(:content_file) do
      instance_double(ContentFile,
                      filepath: 'image1.tif',
                      size: 1024,
                      mime_type: 'image/tiff',
                      view: 'world',
                      download: 'stanford',
                      location: nil,
                      publish: false,
                      preserve: false,
                      use: nil,
                      language_tag: nil)
    end

    it 'renders an empty location cell and no checkmarks' do
      render_inline(component)

      expect(page).to have_css('td', text: 'No role')
      expect(page).to have_css('td', text: '✔', count: 0)
    end
  end

  context 'when the label is blank' do
    let(:content_file_set) do
      instance_double(ContentFileSet, file_set_type: 'file', label: '', content_files: [content_file])
    end

    it 'does not render a label' do
      render_inline(component)

      expect(page).to have_no_css('.card-title', text: 'Label:')
    end
  end
end
