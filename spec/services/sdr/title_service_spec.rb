# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Sdr::TitleService do
  subject(:title) { described_class.call(druid: cocina_object.externalIdentifier) }

  let(:cocina_object) { build(:dro_with_metadata) }

  before do
    allow(Sdr::Repository).to receive(:find_lite).with(druid: cocina_object.externalIdentifier, structural: false)
                                                 .and_return(cocina_object)
  end

  it 'returns the title for the object' do
    expect(title).to eq('factory DRO title')
  end
end
