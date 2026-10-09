# frozen_string_literal: true

# Shared examples for simple bulk action controllers that use BulkActions::BasicForm
# (a druid list or last search, a description, and optionally close version).
#
# Usage:
#   it_behaves_like 'a simple bulk action controller',
#     new_path: :new_bulk_actions_purge_path,
#     create_path: :bulk_actions_purge_path,
#     label: 'Purge',
#     action_type: 'PURGE',
#     job_class: BulkActions::PurgeJob
#
# Set `with_close_version: true` for bulk actions whose form includes the close version checkbox.
RSpec.shared_examples 'a simple bulk action controller' do |new_path:, create_path:, label:, action_type:, # rubocop:disable Metrics/ParameterLists
                                                             job_class:, with_close_version: false|
  let(:user) { create(:user) }

  before do
    sign_in(user)
  end

  describe 'GET new' do
    it 'renders the bulk action form' do
      get send(new_path)

      expect(response).to have_http_status(:ok)
      rendered_page = Capybara.string(response.body)
      expect(rendered_page).to have_css('h1', text: label)
      expect(rendered_page).to have_css("form[action='#{send(create_path)}']")
      expect(rendered_page).to have_field('Enter druid list')
      expect(rendered_page).to have_field('Describe this bulk action')
      if with_close_version
        expect(rendered_page).to have_field('Deposit objects once action is complete', checked: true)
      else
        expect(rendered_page).to have_no_field('Deposit objects once action is complete')
      end
    end
  end

  describe 'POST create' do
    let(:druids) { ['druid:pj757vx3102', 'druid:rt276nw8963'] }
    let(:form_params) do
      { source: 'druids', druid_list: druids.join("\n"), description: "#{label} test items" }
        .merge(with_close_version ? { close_version: '0' } : {})
    end
    let(:expected_job_params) { with_close_version ? { druids:, close_version: false } : { druids: } }

    it 'creates the bulk action and enqueues the job' do
      post send(create_path), params: { bulk_actions_basic: form_params }

      expect(response).to redirect_to(bulk_actions_path)
      expect(flash[:toast]).to eq("#{label} submitted")

      bulk_action = BulkAction.last
      expect(bulk_action.action_type).to eq(action_type)
      expect(bulk_action.description).to eq("#{label} test items")
      expect(bulk_action.user).to eq(user)
      expect(bulk_action.queued?).to be true

      expect(job_class).to have_been_enqueued.with(bulk_action:, **expected_job_params)
    end
  end
end
