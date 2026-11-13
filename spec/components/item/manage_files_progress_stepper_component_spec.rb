# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Item::ManageFilesProgressStepperComponent, type: :component do
  let(:content) { build(:content, step: 'structure') }

  def step_statuses
    page.find('ol[aria-label="Manage files progress"]').all('li').to_h do |step|
      [step.find('.progress-stepper-label').text, step.find('.progress-stepper-status').text]
    end
  end

  it 'renders the steps before the current step completed and the steps after it pending' do
    render_inline(described_class.new(manage_files_flow: Contents::ManageFilesFlow.new(content:, agreement: false)))

    expect(step_statuses).to eq('Item details' => 'Completed', 'Add and edit files' => 'Completed',
                                'Structure files' => 'In progress', 'Deposit' => 'Pending')
  end

  context 'when an agreement' do
    it 'renders the steps without item details' do
      render_inline(described_class.new(manage_files_flow: Contents::ManageFilesFlow.new(content:, agreement: true)))

      expect(step_statuses).to eq('Add and edit files' => 'Completed', 'Structure files' => 'In progress',
                                  'Deposit' => 'Pending')
    end
  end
end
