# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Show::StatusComponent, type: :component do
  subject(:component) { described_class.new(object_status_presenter:, solr_doc: document) }

  let(:object_status_presenter) { ObjectStatusPresenter.new(document:, version_service:, content:) }
  let(:document) { SolrDocPresenter.new(solr_doc: build(:solr_item, druid:, workflow_errors:, object_type:)) }
  let(:druid) { 'druid:bc123df4567' }
  let(:workflow_errors) { [] }
  let(:object_type) { 'item' }

  let(:version_service) do
    instance_double(Sdr::VersionService, assembling?: assembling, accessioning?: accessioning, closed?: closed,
                                         editable?: editable)
  end
  let(:closed) { false }
  let(:editable) { false }
  let(:accessioning) { false }
  let(:assembling) { false }
  let(:content) { nil }

  context 'when the version is open' do
    it 'renders the draft status' do
      render_inline(component)

      expect(page).to have_css('h2', text: 'Draft, not deposited')
      expect(page).to have_button('Edit item', class: 'disabled')
      expect(page).to have_button('Manage files', class: 'disabled')
      expect(page).to have_button('Deposit', class: 'disabled')
    end
  end

  context 'when the item version is editable and the user can edit' do
    let(:closed) { true }
    let(:editable) { true }

    before do
      user = create(:user)
      create(:permission, :edit, workgroup: user.groups.first, target_druid: druid)
      allow(Current).to receive(:user).and_return(user)
    end

    it 'renders an enabled edit item link' do
      render_inline(component)

      expect(page).to have_link('Edit item', href: "/items/#{druid}/edit")
      expect(page).to have_no_css('a.disabled', text: 'Edit item')
    end

    it 'renders an enabled manage files link' do
      render_inline(component)

      expect(page).to have_link('Manage files', href: "/contents/#{druid}/edit")
      expect(page).to have_no_button('Manage files')
    end
  end

  context 'when the item version is not editable' do
    before do
      user = create(:user)
      create(:permission, :edit, workgroup: user.groups.first, target_druid: druid)
      allow(Current).to receive(:user).and_return(user)
    end

    it 'renders a disabled edit item button' do
      render_inline(component)

      expect(page).to have_button('Edit item', class: 'disabled')
      expect(page).to have_no_link('Edit item')
    end
  end

  context 'when the item version is editable but the user cannot edit' do
    let(:closed) { true }
    let(:editable) { true }

    before do
      allow(Current).to receive(:user).and_return(create(:user))
    end

    it 'renders a disabled edit item button' do
      render_inline(component)

      expect(page).to have_button('Edit item', class: 'disabled')
      expect(page).to have_no_link('Edit item')
    end
  end

  context 'when the object is a collection whose version is editable and the user can edit' do
    let(:object_type) { 'collection' }
    let(:closed) { true }
    let(:editable) { true }

    before do
      user = create(:user)
      create(:permission, :edit, workgroup: user.groups.first, target_druid: druid)
      allow(Current).to receive(:user).and_return(user)
    end

    it 'renders a disabled edit collection button' do
      render_inline(component)

      expect(page).to have_button('Edit collection', class: 'disabled')
      expect(page).to have_no_link('Edit collection')
    end
  end

  context 'when the object is an agreement' do
    let(:object_type) { 'agreement' }

    it 'renders the edit agreement button without manage files' do
      render_inline(component)

      expect(page).to have_button('Edit agreement', class: 'disabled')
      expect(page).to have_no_button('Manage files')
    end
  end

  context 'when the object is a collection' do
    let(:object_type) { 'collection' }

    it 'renders the edit collection button without manage files' do
      render_inline(component)

      expect(page).to have_button('Edit collection', class: 'disabled')
      expect(page).to have_no_button('Manage files')
    end
  end

  context 'when the object is an APO' do
    let(:object_type) { 'APO' }

    it 'renders the edit APO button without manage files' do
      render_inline(component)

      expect(page).to have_button('Edit APO', class: 'disabled')
      expect(page).to have_no_button('Manage files')
    end
  end

  context 'when the object is a virtual object' do
    let(:object_type) { 'virtual object' }

    it 'renders the edit virtual object button without manage files' do
      render_inline(component)

      expect(page).to have_button('Edit virtual object', class: 'disabled')
      expect(page).to have_no_button('Manage files')
    end
  end

  context 'when the version is closed and not accessioning' do
    let(:closed) { true }

    it 'renders the deposited status' do
      render_inline(component)

      expect(page).to have_css('h2', text: 'Deposited')
      expect(page).to have_css('h2 i.bi-check-circle-fill')
      expect(page).to have_button('Edit item', class: 'disabled')
      expect(page).to have_button('Manage files', class: 'disabled')
      expect(page).to have_no_button('Deposit')
    end
  end

  context 'when the version is accessioning' do
    let(:closed) { true }
    let(:accessioning) { true }

    it 'renders the depositing status' do
      render_inline(component)

      expect(page).to have_css('h2', text: 'Depositing...')
      expect(page).to have_text('Actions unavailable until deposit is complete.')
    end
  end

  context 'when the version is assembling' do
    let(:assembling) { true }

    it 'renders the assembling status' do
      render_inline(component)

      expect(page).to have_css('h2', text: 'Assembling...')
      expect(page).to have_text('Actions unavailable until deposit is complete.')
    end
  end

  context 'when there are workflow errors' do
    let(:workflow_errors) { ['accessionWF:end-accession:Object cannot be OCRd'] }

    it 'renders the error status with the parsed error message' do
      render_inline(component)

      expect(page).to have_css('h2', text: 'Error')
      expect(page).to have_css('h2 i.bi-exclamation-triangle-fill')
      expect(page).to have_text('end-accession : Object cannot be OCRd')
    end
  end

  context 'when there are workflow errors while the version is still accessioning' do
    let(:closed) { true }
    let(:accessioning) { true }
    let(:workflow_errors) { ['accessionWF:end-accession:Object cannot be OCRd'] }

    it 'renders the error status' do
      render_inline(component)

      expect(page).to have_css('h2', text: 'Error')
    end
  end

  context 'when the content is staging' do
    let(:content) { build(:content, staging_state: 'staging') }

    it 'renders the staging status' do
      render_inline(component)

      expect(page).to have_css('h2', text: 'Staging files')
      expect(page).to have_text('Actions unavailable until deposit is complete.')
    end
  end

  context 'when the content failed staging' do
    let(:content) { build(:content, staging_state: 'staging_failed') }

    it 'renders the staging failed status with the support email' do
      render_inline(component)

      expect(page).to have_css('h2', text: 'Staging failed')
      expect(page).to have_css('h2 i.bi-exclamation-triangle-fill')
      expect(page).to have_text("Files could not be staged. Contact SDR support at #{Settings.support_email}")
      expect(page).to have_link(Settings.support_email, href: "mailto:#{Settings.support_email}")
      expect(page).to have_button('Manage files', class: 'disabled')
    end

    context 'when the item version is editable and the user can edit' do
      let(:editable) { true }

      before do
        user = create(:user)
        create(:permission, :edit, workgroup: user.groups.first, target_druid: druid)
        allow(Current).to receive(:user).and_return(user)
      end

      it 'renders an enabled manage files link' do
        render_inline(component)

        expect(page).to have_link('Manage files', href: "/contents/#{druid}/edit")
        expect(page).to have_no_button('Manage files')
      end
    end
  end
end
