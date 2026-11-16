# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Show object Redeposit with Goobi button' do
  include_context 'with show page object client'

  let(:druid) { 'druid:bc123df4567' }
  let(:content_type) { Cocina::Models::ObjectType.book }
  let(:user) { create(:user, :reader) }
  let(:permission_trait) { :edit }
  let(:rendered_page) { Capybara.string(response.body) }

  before do
    allow(Sdr::Repository).to receive_messages(
      lock: object_lock,
      find: build(:dro_with_metadata, id: druid, type: content_type),
      find_solr: { Search::Fields::ID => druid, Search::Fields::TITLE => 'My object',
                   Search::Fields::OBJECT_TYPES => ['item'] }
    )
    create(:permission, permission_trait, workgroup: user.groups.first, target_druid: druid)
    sign_in(user)
  end

  context 'when a book Item can be redeposited with Goobi' do
    it 'renders an enabled button in the Update section, after Actions' do
      get "/objects/#{druid}"

      expect(rendered_page).to have_css('h2', text: 'Update')
      expect(rendered_page).to have_css("form[action='/objects/#{druid}/redeposit_with_goobi']")
      expect(rendered_page).to have_css('button:not(.disabled)', exact_text: 'Redeposit with Goobi')
      expect(response.body.index('Actions')).to be < response.body.index('Update')
    end
  end

  context 'with an image Item' do
    let(:content_type) { Cocina::Models::ObjectType.image }

    it 'renders the button' do
      get "/objects/#{druid}"

      expect(rendered_page).to have_button('Redeposit with Goobi')
    end
  end

  context 'with another content type' do
    let(:content_type) { Cocina::Models::ObjectType.map }

    it 'renders neither the Update section nor the button' do
      get "/objects/#{druid}"

      expect(rendered_page).to have_no_css('h2', text: 'Update')
      expect(rendered_page).to have_no_button('Redeposit with Goobi')
    end
  end

  context 'when a workflow is active' do
    let(:workflows_xml) do
      <<~XML
        <workflows objectId="#{druid}">
          <workflow objectId="#{druid}" id="accessionWF">
            <process version="1" status="started" name="shelve"/>
          </workflow>
        </workflows>
      XML
    end

    it 'renders a disabled button' do
      get "/objects/#{druid}"

      expect(rendered_page).to have_button('Redeposit with Goobi', class: 'disabled', disabled: true)
    end
  end

  context 'when goobiWF was started for the open version' do
    let(:workflows_xml) do
      <<~XML
        <workflows objectId="#{druid}">
          <workflow objectId="#{druid}" id="goobiWF">
            <process version="1" status="completed" name="start"/>
            <process version="1" status="completed" name="goobi-notify"/>
          </workflow>
        </workflows>
      XML
    end

    it 'renders a disabled button' do
      get "/objects/#{druid}"

      expect(rendered_page).to have_button('Redeposit with Goobi', class: 'disabled', disabled: true)
    end
  end

  context 'when the user cannot update the object' do
    let(:permission_trait) { :read_restricted }

    it 'renders a disabled button without checking the workflows' do
      get "/objects/#{druid}"

      expect(rendered_page).to have_button('Redeposit with Goobi', class: 'disabled', disabled: true)
      expect(object_client).not_to have_received(:workflows)
    end
  end
end
