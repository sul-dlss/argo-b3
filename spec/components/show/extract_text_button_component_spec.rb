# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Show::ExtractTextButtonComponent, type: :component do
  subject(:component) { described_class.new(solr_doc:, object_status_presenter:, content_type:) }

  let(:druid) { 'druid:bc123df4567' }
  let(:content_type) { Cocina::Models::ObjectType.book }
  let(:solr_doc) { SolrDocPresenter.new(solr_doc: build(:solr_item, druid:)) }
  let(:object_status_presenter) { ObjectStatusPresenter.new(solr_doc:, version_service:, content: nil) }
  # A closed version: Deposited.
  let(:version_service) { version_service_double(open?: false, closed?: true, openable?: true, closeable?: false) }
  let(:user) { create(:user) }
  let(:button_selector) { "form[action='/items/#{druid}/text_extraction/new'] button" }

  before { allow(Current).to receive(:user).and_return(user) }

  context 'when the user can edit a deposited book' do
    before { create(:permission, :edit, workgroup: user.groups.first, target_druid: druid) }

    it 'renders an enabled button' do
      render_inline(component)

      expect(page).to have_css("#{button_selector}:not([disabled])", text: 'Extract text')
    end
  end

  context 'when the user can edit a book in draft' do
    let(:version_service) { version_service_double(version: 2) }

    before { create(:permission, :edit, workgroup: user.groups.first, target_druid: druid) }

    it 'renders an enabled button' do
      render_inline(component)

      expect(page).to have_css("#{button_selector}:not([disabled])", text: 'Extract text')
    end
  end

  context 'when the item is registered' do
    let(:version_service) { version_service_double(version: 1) }

    before { create(:permission, :edit, workgroup: user.groups.first, target_druid: druid) }

    it 'renders a disabled button' do
      render_inline(component)

      expect(page).to have_css("#{button_selector}[disabled]", text: 'Extract text')
    end
  end

  context 'when the item is assembling' do
    let(:version_service) { version_service_double(version: 2, assembling?: true, closeable?: false) }

    before { create(:permission, :edit, workgroup: user.groups.first, target_druid: druid) }

    it 'renders a disabled button' do
      render_inline(component)

      expect(page).to have_css("#{button_selector}[disabled]", text: 'Extract text')
    end
  end

  context 'when the item has a content type without text extraction' do
    let(:content_type) { Cocina::Models::ObjectType.object }

    before { create(:permission, :edit, workgroup: user.groups.first, target_druid: druid) }

    it 'renders a disabled button' do
      render_inline(component)

      expect(page).to have_css("#{button_selector}[disabled]", text: 'Extract text')
    end
  end

  context 'when the item is media' do
    let(:content_type) { Cocina::Models::ObjectType.media }

    before { create(:permission, :edit, workgroup: user.groups.first, target_druid: druid) }

    context 'with speech to text turned on' do
      before { allow(Settings.feature_flags).to receive(:speech_to_text_workflow).and_return(true) }

      it 'renders an enabled button' do
        render_inline(component)

        expect(page).to have_css("#{button_selector}:not([disabled])", text: 'Extract text')
      end
    end

    context 'with speech to text turned off' do
      before { allow(Settings.feature_flags).to receive(:speech_to_text_workflow).and_return(false) }

      it 'renders a disabled button' do
        render_inline(component)

        expect(page).to have_css("#{button_selector}[disabled]", text: 'Extract text')
      end
    end
  end

  context 'when the user cannot edit the item' do
    it 'renders a disabled button' do
      render_inline(component)

      expect(page).to have_css("#{button_selector}[disabled]", text: 'Extract text')
    end
  end
end
