# frozen_string_literal: true

require 'rails_helper'

RSpec.describe WorkflowGrid::ResetButtonComponent, type: :component do
  let(:component) do
    described_class.new(workflow_name: 'accessionWF', process_name: 'update-doi', status:, search_form:)
  end

  let(:status) { 'error' }
  let(:search_form) { SearchForm.new(query: 'test') }

  it 'renders the reset button when status is error' do
    render_inline(component)

    expect(page).to have_css('form[action="/workflow_grid/reset?process_name=update-doi&workflow_name=accessionWF"]')
    expect(page).to have_field('search[query]', with: 'test', type: 'hidden')
    expect(page).to have_button('Reset', type: 'submit')
  end

  context 'when status is not error' do
    let(:status) { 'completed' }

    it 'does not render the reset button' do
      expect(component.render?).to be false
    end
  end
end
