# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Elements::ProgressStepperStepComponent, type: :component do
  let(:component) { described_class.new(number: 2, label: 'Check files', status:) }

  context 'when completed' do
    let(:status) { :completed }

    it 'renders the step with a check in its circle' do
      render_inline(component)

      step = page.find('li.progress-stepper-step-completed:not([aria-current])')
      expect(step).to have_css('.progress-stepper-circle .bi-check-lg')
      expect(step).to have_css('.progress-stepper-status', exact_text: 'Completed')
    end
  end

  context 'when in progress' do
    let(:status) { :in_progress }

    it 'renders the step as the current step' do
      render_inline(component)

      step = page.find('li.progress-stepper-step-in-progress[aria-current="step"]')
      expect(step).to have_css('.progress-stepper-number', exact_text: 'Step 2')
      expect(step).to have_css('.progress-stepper-label', exact_text: 'Check files')
      expect(step).to have_css('.progress-stepper-status', exact_text: 'In progress')
      expect(step).to have_no_css('.bi-check-lg')
    end
  end

  context 'when pending' do
    let(:status) { :pending }

    it 'renders the step without a check' do
      render_inline(component)

      step = page.find('li.progress-stepper-step-pending:not([aria-current])')
      expect(step).to have_no_css('.bi-check-lg')
      expect(step).to have_css('.progress-stepper-status', exact_text: 'Pending')
    end
  end

  it 'hides the circle and line from assistive technology' do
    render_inline(described_class.new(number: 1, label: 'Deposit', status: :pending))

    expect(page).to have_css('.progress-stepper-marker[aria-hidden="true"] .progress-stepper-circle')
    expect(page).to have_css('.progress-stepper-marker[aria-hidden="true"] .progress-stepper-line')
  end
end
