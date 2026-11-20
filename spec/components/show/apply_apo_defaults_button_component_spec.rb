# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Show::ApplyApoDefaultsButtonComponent, type: :component do
  subject(:component) { described_class.new(solr_doc:, object_status_presenter:) }

  let(:druid) { 'druid:bc123df4567' }
  let(:solr_doc) { SolrDocPresenter.new(solr_doc: build(:solr_item, druid:)) }
  let(:object_status_presenter) { ObjectStatusPresenter.new(solr_doc:, version_service:, content:) }
  let(:content) { nil }
  # A closed version: Deposited.
  let(:version_service) { version_service_double(open?: false, closed?: true, openable?: true, closeable?: false) }
  let(:user) { create(:user) }
  let(:button_selector) { "form[action='/objects/#{druid}/apo_defaults/new'] button" }

  before { allow(Current).to receive(:user).and_return(user) }

  context 'when the user can edit the object' do
    before { create(:permission, :edit, workgroup: user.groups.first, target_druid: druid) }

    context 'when it is Deposited' do
      it 'renders an enabled button' do
        render_inline(component)

        expect(page).to have_css("#{button_selector}:not([disabled])", text: 'Apply APO defaults')
      end
    end

    context 'when it is a Draft' do
      let(:version_service) { version_service_double(version: 2) }

      it 'renders an enabled button' do
        render_inline(component)

        expect(page).to have_css("#{button_selector}:not([disabled])", text: 'Apply APO defaults')
      end
    end

    context 'when it is Registered' do
      let(:version_service) { version_service_double(version: 1) }

      it 'renders an enabled button' do
        render_inline(component)

        expect(page).to have_css("#{button_selector}:not([disabled])", text: 'Apply APO defaults')
      end
    end

    context 'when it is Staging' do
      let(:version_service) { version_service_double(version: 2) }
      let(:content) { create(:content, :mutable, druid:, staging_state: 'staging') }

      it 'renders a disabled button' do
        render_inline(component)

        expect(page).to have_css("#{button_selector}[disabled]", text: 'Apply APO defaults')
      end
    end

    context 'when it is Assembling' do
      let(:version_service) { version_service_double(version: 2, assembling?: true, closeable?: false) }

      it 'renders a disabled button' do
        render_inline(component)

        expect(page).to have_css("#{button_selector}[disabled]", text: 'Apply APO defaults')
      end
    end

    context 'when it is Depositing' do
      let(:version_service) do
        version_service_double(open?: false, accessioning?: true, openable?: false, closeable?: false)
      end

      it 'renders a disabled button' do
        render_inline(component)

        expect(page).to have_css("#{button_selector}[disabled]", text: 'Apply APO defaults')
      end
    end

    context 'when it is In Error' do
      let(:solr_doc) do
        SolrDocPresenter.new(solr_doc: build(:solr_item, druid:, workflow_errors: ['accessionWF:shelve:Failed']))
      end

      it 'renders a disabled button' do
        render_inline(component)

        expect(page).to have_css("#{button_selector}[disabled]", text: 'Apply APO defaults')
      end
    end
  end

  context 'when the user cannot edit the object' do
    it 'renders a disabled button' do
      render_inline(component)

      expect(page).to have_css("#{button_selector}[disabled]", text: 'Apply APO defaults')
    end
  end
end
