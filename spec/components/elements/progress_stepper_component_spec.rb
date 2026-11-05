# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Elements::ProgressStepperComponent, type: :component do
  let(:component) do
    described_class.new(label: 'Deposit progress', steps: [
                          { label: 'Discover files', status: :completed },
                          { label: 'Check files', status: :in_progress },
                          { label: 'Deposit', status: :pending }
                        ])
  end

  it 'renders the numbered steps in order with their statuses' do
    render_inline(component)

    list = page.find('ol.progress-stepper[aria-label="Deposit progress"]')
    steps = list.all('li').map do |step|
      [step.find('.progress-stepper-number').text, step.find('.progress-stepper-label').text,
       step.find('.progress-stepper-status').text]
    end
    expect(steps).to eq([['Step 1', 'Discover files', 'Completed'],
                         ['Step 2', 'Check files', 'In progress'],
                         ['Step 3', 'Deposit', 'Pending']])
  end

  it 'marks the step in progress as the current step' do
    render_inline(component)

    expect(page).to have_css('li[aria-current="step"]', count: 1)
    expect(page).to have_css('li.progress-stepper-step-in-progress[aria-current="step"]', text: 'Check files')
  end

  it 'renders a check in the circle of a completed step only' do
    render_inline(component)

    expect(page).to have_css('li.progress-stepper-step-completed .progress-stepper-circle .bi-check-lg')
    expect(page).to have_css('.bi-check-lg', count: 1)
  end

  it 'hides the circles and lines from assistive technology' do
    render_inline(component)

    expect(page).to have_css('.progress-stepper-marker[aria-hidden="true"]', count: 3)
  end
end
