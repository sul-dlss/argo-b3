# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Redeposit bulk action' do
  let(:user) { create(:user) }
  let(:rendered_page) { Capybara.string(response.body) }
  let(:druids) { ['druid:pj757vx3102', 'druid:rt276nw8963'] }

  before { sign_in user }

  describe 'new' do
    it 'notes that drafts will be opened and requires a version description' do
      get new_bulk_actions_redeposit_path

      expect(rendered_page).to have_css('.alert-info',
                                        text: 'If objects are not already in draft state, a new draft will be ' \
                                              'opened before depositing.')
      expect(rendered_page).to have_field('Version description')
      expect(rendered_page.find('label', text: 'Version description')).to have_css('span.required')
      expect(rendered_page).to have_text('The version description will be applied to new versions and to drafts ' \
                                         'that do not already have one.')
    end
  end

  describe 'create' do
    let(:form_params) do
      { source: 'druids', druid_list: druids.join("\n"), description: 'Reaccession items',
        version_description: '  Reaccession  ' }
    end

    it 'creates the bulk action and enqueues the job with the version description' do
      post bulk_actions_redeposit_path, params: { bulk_actions_redeposit: form_params }

      expect(response).to redirect_to(bulk_actions_path)
      expect(flash[:toast]).to eq('Redeposit submitted')

      bulk_action = BulkAction.last
      expect(bulk_action.action_type).to eq('REDEPOSIT')
      expect(bulk_action.description).to eq('Reaccession items')
      expect(BulkActions::RedepositJob).to have_been_enqueued
        .with(bulk_action:, druids:, version_description: 'Reaccession')
    end

    context 'without a version description' do
      it 'renders the form with the error and does not create the bulk action' do
        post bulk_actions_redeposit_path,
             params: { bulk_actions_redeposit: form_params.merge(version_description: ' ') }

        expect(response).to have_http_status(:unprocessable_content)
        expect(rendered_page).to have_invalid_feedback('Version description', "can't be blank")
        expect(BulkAction.count).to eq(0)
      end
    end
  end
end
