# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Show unsaved content changes' do
  include_context 'with show page object client'

  let(:druid) { 'druid:bc123df4567' }
  let(:user) { create(:user) }
  let(:cocina_object) { build(:dro_with_metadata, id: druid) }
  let(:solr_doc) do
    {
      Search::Fields::ID => druid,
      Search::Fields::OBJECT_TYPES => ['item'],
      Search::Fields::TITLE => 'My item'
    }
  end

  before do
    create(:permission, :edit, workgroup: user.groups.first, target_druid: druid)
    allow(Sdr::WorkflowService).to receive(:workflows_for).and_return([])
    allow(Sdr::Repository).to receive_messages(find_solr: solr_doc, find: cocina_object)

    sign_in(user)
  end

  context 'when the files have unsaved changes' do
    before do
      mutable_content = create(:content, :mutable, druid:, lock: cocina_object.lock)
      # A file that has not been staged is an unsaved change.
      create(:content_file_binary, content: mutable_content, file_location: 'attached')
    end

    it 'disables the deposit button with a note' do
      get "/objects/#{druid}"

      rendered_page = Capybara.string(response.body)
      expect(rendered_page).to have_button('Deposit', disabled: true)
      expect(rendered_page).to have_text('Files have unsaved changes. Deposit from Manage files.')
    end
  end

  context 'when the files have no unsaved changes' do
    it 'enables the deposit button' do
      get "/objects/#{druid}"

      rendered_page = Capybara.string(response.body)
      expect(rendered_page).to have_button('Deposit', disabled: false)
      expect(rendered_page).to have_no_text('Files have unsaved changes.')
    end
  end
end
