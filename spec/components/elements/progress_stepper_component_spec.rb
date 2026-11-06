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
end
