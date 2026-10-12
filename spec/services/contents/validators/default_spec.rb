# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Contents::Validators::Default do
  subject(:result) { described_class.call(content:, dark: false) }

  let(:content) { create(:content, druid: 'druid:bc123df4567') }

  it 'returns a result without errors or warnings' do
    expect(result).to have_attributes(errors: [], warnings: [])
  end
end
