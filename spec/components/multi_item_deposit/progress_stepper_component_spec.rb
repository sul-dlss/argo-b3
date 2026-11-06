# frozen_string_literal: true

require 'rails_helper'

RSpec.describe MultiItemDeposit::ProgressStepperComponent, type: :component do
  let(:component) { described_class.new(multi_item_deposit_action:) }

  def step_statuses
    page.find('ol[aria-label="Multi-item deposit progress"]').all('li').to_h do |step|
      [step.find('.progress-stepper-label').text, step.find('.progress-stepper-status').text]
    end
  end

  context 'when discovery has not completed' do
    let(:multi_item_deposit_action) { create(:multi_item_deposit_action) }

    it 'renders discovery in progress and the other steps pending' do
      render_inline(component)

      expect(step_statuses).to eq('Discover files and check manifest' => 'In progress',
                                  'Configure deposit and check files' => 'Pending',
                                  'Deposit' => 'Pending')
    end
  end

  context 'when discovery has completed with errors' do
    let(:multi_item_deposit_action) { create(:multi_item_deposit_action, discovery_completed_at: Time.current) }

    before do
      create(:item_deposit_action, multi_item_deposit_action:, discovery_errors: ['Object not found'])
    end

    it 'renders discovery in progress' do
      render_inline(component)

      expect(step_statuses['Discover files and check manifest']).to eq('In progress')
    end
  end

  context 'when discovery has succeeded in the discovery step' do
    let(:multi_item_deposit_action) { create(:multi_item_deposit_action, discovery_completed_at: Time.current) }

    it 'renders discovery completed and the other steps pending' do
      render_inline(component)

      expect(step_statuses).to eq('Discover files and check manifest' => 'Completed',
                                  'Configure deposit and check files' => 'Pending',
                                  'Deposit' => 'Pending')
    end
  end

  context 'when in the structure step and structuring has not completed' do
    let(:multi_item_deposit_action) do
      create(:multi_item_deposit_action, step: 'structure', discovery_completed_at: Time.current)
    end

    it 'renders structure in progress' do
      render_inline(component)

      expect(step_statuses).to eq('Discover files and check manifest' => 'Completed',
                                  'Configure deposit and check files' => 'In progress',
                                  'Deposit' => 'Pending')
    end
  end

  context 'when in the structure step and structuring has completed with errors' do
    let(:multi_item_deposit_action) do
      create(:multi_item_deposit_action, step: 'structure', discovery_completed_at: Time.current,
                                         structuring_completed_at: Time.current)
    end

    before do
      create(:item_deposit_action, multi_item_deposit_action:, structural_csv_errors: ['No rows'])
    end

    it 'renders structure in progress' do
      render_inline(component)

      expect(step_statuses['Configure deposit and check files']).to eq('In progress')
    end
  end

  context 'when in the structure step and structuring has succeeded' do
    let(:multi_item_deposit_action) do
      create(:multi_item_deposit_action, step: 'structure', discovery_completed_at: Time.current,
                                         structuring_completed_at: Time.current)
    end

    it 'renders structure completed' do
      render_inline(component)

      expect(step_statuses).to eq('Discover files and check manifest' => 'Completed',
                                  'Configure deposit and check files' => 'Completed',
                                  'Deposit' => 'Pending')
    end
  end

  context 'when returned to the discovery step after structuring succeeded' do
    let(:multi_item_deposit_action) do
      create(:multi_item_deposit_action, step: 'discovery', discovery_completed_at: Time.current,
                                         structuring_completed_at: Time.current)
    end

    it 'renders structure pending' do
      render_inline(component)

      expect(step_statuses['Configure deposit and check files']).to eq('Pending')
    end
  end

  context 'when in the deposit step' do
    let(:multi_item_deposit_action) do
      create(:multi_item_deposit_action, step: 'deposit', discovery_completed_at: Time.current,
                                         structuring_completed_at: Time.current)
    end

    it 'renders deposit in progress and the earlier steps completed' do
      render_inline(component)

      expect(step_statuses).to eq('Discover files and check manifest' => 'Completed',
                                  'Configure deposit and check files' => 'Completed',
                                  'Deposit' => 'In progress')
    end
  end
end
