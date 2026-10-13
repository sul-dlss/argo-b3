# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Item::ContentValidationAlertsComponent, type: :component do
  let(:component) { described_class.new(content_validation_result:) }

  context 'with errors and warnings' do
    let(:content_validation_result) do
      Contents::Validators::Result.new(errors: ['Resource 1 has an error.'], warnings: ['Resource 2 has a warning.'])
    end

    it 'renders an alert for each' do
      render_inline(component)

      expect(page).to have_css('.alert-danger', text: 'Content errors')
      expect(page).to have_css('.alert-danger li', text: 'Resource 1 has an error.')
      expect(page).to have_css('.alert-warning', text: 'Content warnings')
      expect(page).to have_css('.alert-warning li', text: 'Resource 2 has a warning.')
    end
  end

  context 'with only warnings' do
    let(:content_validation_result) { Contents::Validators::Result.new(warnings: ['Resource 2 has a warning.']) }

    it 'renders only the warnings alert' do
      render_inline(component)

      expect(page).to have_no_css('.alert-danger')
      expect(page).to have_css('.alert-warning li', text: 'Resource 2 has a warning.')
    end
  end

  context 'with no errors or warnings' do
    let(:content_validation_result) { Contents::Validators::Result.new }

    it 'renders nothing' do
      render_inline(component)

      expect(page).to have_no_css('.alert')
    end
  end
end
