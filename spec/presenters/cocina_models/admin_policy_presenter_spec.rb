# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CocinaModels::AdminPolicyPresenter do
  subject(:presenter) { described_class.new(cocina_model) }

  let(:cocina_model) { CocinaModels::Factory.build(cocina_object) }
  let(:cocina_object) { build(:admin_policy_with_metadata) }

  describe '#title' do
    it 'returns the display title' do
      expect(presenter.title).to eq('factory APO title')
    end
  end
end
