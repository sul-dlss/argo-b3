# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Show::WorkflowProcessActionsComponent, type: :component do
  let(:component) { described_class.new(process:, solr_doc:) }

  let(:druid) { 'druid:bc123df4567' }
  let(:solr_doc) { SolrDocPresenter.new(solr_doc: { Search::Fields::ID => druid }) }
  let(:process) do
    instance_double(Dor::Services::Response::Process, workflow_name: 'accessionWF', name: 'shelve',
                                                      version: 2, status:)
  end
  let(:status) { 'error' }
  let(:user) { create(:user) }
  let(:path) { '/objects/druid:bc123df4567/workflows/accessionWF/processes/shelve' }

  before do
    allow(Current).to receive(:user).and_return(user)
  end

  context 'when the user is an admin' do
    let(:user) { create(:user, :admin) }

    it 'renders retry, skip, and complete buttons' do
      render_inline(component)

      expect(page).to have_button(class: 'btn-outline-primary', count: 3)
      expect(page).to have_css("form[action='#{path}'] input[name='_method'][value='patch']", count: 3, visible: :all)
      expect(page).to have_css("form[action='#{path}']:has(input[name='status'][value='waiting'])", text: 'Retry')
      expect(page).to have_css("form[action='#{path}']:has(input[name='status'][value='skipped'])", text: 'Skip')
      expect(page).to have_css("form[action='#{path}']:has(input[name='status'][value='completed'])", text: 'Complete')
      expect(page).to have_css("input[name='version'][value='2']", count: 3, visible: :all)
    end
  end

  context 'when the user can edit the object' do
    before do
      create(:permission, :edit, workgroup: user.groups.first, target_druid: druid)
    end

    it 'renders only a retry button' do
      render_inline(component)

      expect(page).to have_css("form[action='#{path}']:has(input[name='status'][value='waiting'])", text: 'Retry')
      expect(page).to have_button('Retry', disabled: false)
      expect(page).to have_no_button('Skip')
      expect(page).to have_no_button('Complete')
    end
  end

  context 'when the user cannot edit the object' do
    it 'renders only a disabled retry button' do
      render_inline(component)

      expect(page).to have_button('Retry', disabled: true)
      expect(page).to have_no_button('Skip')
      expect(page).to have_no_button('Complete')
    end
  end

  context 'when the process is not in error' do
    let(:status) { 'waiting' }
    let(:user) { create(:user, :admin) }

    it 'renders nothing' do
      render_inline(component)

      expect(page).to have_no_button
    end
  end
end
