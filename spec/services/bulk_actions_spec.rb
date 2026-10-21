# frozen_string_literal: true

require 'rails_helper'

RSpec.describe BulkActions do
  describe '.all' do
    subject(:configs) { described_class.all }

    it 'returns only bulk action configs' do
      expect(configs).to all(be_a(BulkActions::Config))
    end

    it 'includes the bulk action types' do
      expect(configs.map(&:action_type)).to include('ADD_WORKFLOW', 'REDEPOSIT', 'REGISTER_CSV')
    end
  end
end
