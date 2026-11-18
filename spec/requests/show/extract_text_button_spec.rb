# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Show object Extract text button' do
  include_context 'with show page object client'

  let(:druid) { 'druid:bc123df4567' }
  let(:object_type) { 'item' }
  let(:content_type) { Cocina::Models::ObjectType.book }
  let(:cocina_object) { build(:dro_with_metadata, id: druid, type: content_type, version: 2) }
  let(:user) { create(:user, :reader) }
  let(:rendered_page) { Capybara.string(response.body) }
  let(:button_selector) { "form[action='/items/#{druid}/text_extraction/new'] button" }
  # A closed version: Deposited.
  let(:version_status) do
    instance_double(Dor::Services::Client::ObjectVersion::VersionStatus, assembling?: false, accessioning?: false,
                                                                         closed?: true, openable?: true,
                                                                         closeable?: false, open?: false,
                                                                         discardable?: false, version: 2)
  end

  before do
    allow(Sdr::Repository).to receive_messages(
      lock: object_lock,
      find: cocina_object,
      find_solr: { Search::Fields::ID => druid, Search::Fields::TITLE => 'My object',
                   Search::Fields::OBJECT_TYPES => [object_type] }
    )
    sign_in(user)
  end

  context 'when the user can edit a deposited book' do
    before { create(:permission, :edit, workgroup: user.groups.first, target_druid: druid) }

    it 'renders an enabled button in the Update list' do
      get "/objects/#{druid}"

      expect(rendered_page).to have_css('h2', text: 'Update')
      expect(rendered_page).to have_text('(creates new version)')
      expect(rendered_page).to have_css("#{button_selector}:not([disabled])", text: 'Extract text')
    end
  end

  context 'when the user can edit a book in draft' do
    let(:version_status) do
      instance_double(Dor::Services::Client::ObjectVersion::VersionStatus, assembling?: false, accessioning?: false,
                                                                           closed?: false, openable?: false,
                                                                           closeable?: true, open?: true,
                                                                           discardable?: true, version: 2)
    end

    before { create(:permission, :edit, workgroup: user.groups.first, target_druid: druid) }

    it 'renders an enabled button' do
      get "/objects/#{druid}"

      expect(rendered_page).to have_css("#{button_selector}:not([disabled])", text: 'Extract text')
    end
  end

  context 'when the item is registered' do
    let(:version_status) do
      instance_double(Dor::Services::Client::ObjectVersion::VersionStatus, assembling?: false, accessioning?: false,
                                                                           closed?: false, openable?: false,
                                                                           closeable?: true, open?: true,
                                                                           discardable?: false, version: 1)
    end

    before { create(:permission, :edit, workgroup: user.groups.first, target_druid: druid) }

    it 'renders a disabled button' do
      get "/objects/#{druid}"

      expect(rendered_page).to have_css("#{button_selector}[disabled]", text: 'Extract text')
    end
  end

  context 'when the item is assembling' do
    let(:version_status) do
      instance_double(Dor::Services::Client::ObjectVersion::VersionStatus, assembling?: true, accessioning?: false,
                                                                           closed?: false, openable?: false,
                                                                           closeable?: false, open?: true,
                                                                           discardable?: false, version: 2)
    end

    before { create(:permission, :edit, workgroup: user.groups.first, target_druid: druid) }

    it 'renders a disabled button' do
      get "/objects/#{druid}"

      expect(rendered_page).to have_css("#{button_selector}[disabled]", text: 'Extract text')
    end
  end

  context 'when the item has a content type without text extraction' do
    let(:content_type) { Cocina::Models::ObjectType.object }

    before { create(:permission, :edit, workgroup: user.groups.first, target_druid: druid) }

    it 'renders a disabled button' do
      get "/objects/#{druid}"

      expect(rendered_page).to have_css("#{button_selector}[disabled]", text: 'Extract text')
    end
  end

  context 'when the item is media' do
    let(:content_type) { Cocina::Models::ObjectType.media }

    before { create(:permission, :edit, workgroup: user.groups.first, target_druid: druid) }

    context 'with speech to text turned on' do
      before { allow(Settings.feature_flags).to receive(:speech_to_text_workflow).and_return(true) }

      it 'renders an enabled button' do
        get "/objects/#{druid}"

        expect(rendered_page).to have_css("#{button_selector}:not([disabled])", text: 'Extract text')
      end
    end

    context 'with speech to text turned off' do
      before { allow(Settings.feature_flags).to receive(:speech_to_text_workflow).and_return(false) }

      it 'renders a disabled button' do
        get "/objects/#{druid}"

        expect(rendered_page).to have_css("#{button_selector}[disabled]", text: 'Extract text')
      end
    end
  end

  context 'when the user cannot edit the item' do
    before { create(:permission, :read_restricted, workgroup: user.groups.first, target_druid: druid) }

    it 'renders a disabled button' do
      get "/objects/#{druid}"

      expect(rendered_page).to have_css("#{button_selector}[disabled]", text: 'Extract text')
    end
  end

  context 'when the object is a collection' do
    let(:object_type) { 'collection' }
    let(:cocina_object) { build(:collection_with_metadata, id: druid) }

    before { create(:permission, :edit, workgroup: user.groups.first, target_druid: druid) }

    it 'does not render the button' do
      get "/objects/#{druid}"

      expect(response).to have_http_status(:ok)
      expect(rendered_page).to have_no_button('Extract text')
    end
  end
end
