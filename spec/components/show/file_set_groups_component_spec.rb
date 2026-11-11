# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Show::FileSetGroupsComponent, type: :component do
  let(:component) { described_class.new(content_file_sets:, content_type:) }

  def content_file_set(file_set_type, label)
    instance_double(ContentFileSet, file_set_type:, label:, content_files: [])
  end

  context 'with a book' do
    let(:content_type) { Cocina::Models::ObjectType.book }
    let(:content_file_sets) do
      [content_file_set('object', 'Object 1'), content_file_set('page', 'Page 1'), content_file_set('page', 'Page 2')]
    end

    it 'renders pages first, then supplemental files, with each resource numbered by its position' do
      render_inline(component)

      expect(page).to have_css('h3.text-uppercase button[aria-expanded="true"]', text: 'Pages (2)')
      expect(page).to have_css('h3.text-uppercase button[aria-expanded="true"]', text: 'Supplemental files (1)')
      expect(page.all('h3').map { |heading| heading.text.strip }).to eq(['Pages (2)', 'Supplemental files (1)'])
      expect(page).to have_css('#file-set-group-pages .card-title', text: 'Resource (2): page')
      expect(page).to have_css('#file-set-group-pages .card-title', text: 'Resource (3): page')
      expect(page).to have_css('#file-set-group-supplemental-files .card-title', text: 'Resource (1): object')
      resource_headings = page.all('h4').map { |heading| heading.text.strip }
      expect(resource_headings).to eq(['Resource (2):', 'Resource (3):', 'Resource (1):'])
    end
  end

  context 'with media' do
    let(:content_type) { Cocina::Models::ObjectType.media }
    let(:content_file_sets) do
      [content_file_set('audio', 'Audio 1'), content_file_set('video', 'Video 1'), content_file_set('image', 'Image 1')]
    end

    it 'groups audio, video, and image resources as media and omits empty groups' do
      render_inline(component)

      expect(page).to have_css('h3', text: 'Media (3)')
      expect(page).to have_no_css('h3', text: 'Supplemental files')
    end
  end

  context 'with a map' do
    let(:content_type) { Cocina::Models::ObjectType.map }
    let(:content_file_sets) { [content_file_set('image', 'Image 1'), content_file_set('file', 'File 1')] }

    it 'groups image resources as images' do
      render_inline(component)

      expect(page).to have_css('#file-set-group-images .card-title', text: 'Resource (1): image')
      expect(page).to have_css('#file-set-group-supplemental-files .card-title', text: 'Resource (2): file')
    end
  end

  context 'with a document' do
    let(:content_type) { Cocina::Models::ObjectType.document }
    let(:content_file_sets) { [content_file_set('document', 'Document 1')] }

    it 'groups document resources as documents' do
      render_inline(component)

      expect(page).to have_css('h3', text: 'Documents (1)')
    end
  end

  context 'with a content type that is not grouped' do
    let(:content_type) { Cocina::Models::ObjectType.object }
    let(:content_file_sets) { [content_file_set('file', 'File 1'), content_file_set('file', 'File 2')] }

    it 'renders the resources without groups, with each resource heading one level below the section' do
      render_inline(component)

      expect(page).to have_no_css('button[aria-expanded]')
      expect(page).to have_no_css('h4')
      expect(page.all('h3').map { |heading| heading.text.strip }).to eq(['Resource (1):', 'Resource (2):'])
      expect(page).to have_css('.card-title', text: 'Resource (1): file')
      expect(page).to have_css('.card-title', text: 'Resource (2): file')
    end
  end
end
