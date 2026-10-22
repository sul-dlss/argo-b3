# frozen_string_literal: true

require 'rails_helper'

RSpec.describe MultiItemDeposit::DepositForm do
  let(:multi_item_deposit_action) { create(:multi_item_deposit_action) }

  def build_form(**attributes)
    described_class.new(attributes).tap { |form| form.multi_item_deposit_action = multi_item_deposit_action }
  end

  context 'when every Item Deposit is an initial version' do
    before do
      create_list(:item_deposit_action, 2, multi_item_deposit_action:, initial_version: true)
    end

    it 'prefills the initial version description' do
      form = described_class.from_model(multi_item_deposit_action)

      expect(form.version_description).to eq('Initial version')
    end

    it 'sets the initial version description when not submitted' do
      form = build_form

      expect(form).to be_valid
      expect(form.version_description).to eq('Initial version')
    end
  end

  context 'when some Item Deposits are not initial versions' do
    before do
      create(:item_deposit_action, multi_item_deposit_action:, initial_version: true)
      create(:item_deposit_action, multi_item_deposit_action:, initial_version: false)
    end

    it 'does not prefill the version description' do
      form = described_class.from_model(multi_item_deposit_action)

      expect(form.version_description).to be_nil
    end

    it 'requires a version description' do
      form = build_form(version_description: '  ')

      expect(form).not_to be_valid
      expect(form.errors[:version_description]).to be_present
    end

    it 'is valid with a version description' do
      form = build_form(version_description: '  Fixed typos  ')

      expect(form).to be_valid
      expect(form.version_description).to eq('Fixed typos')
    end
  end

  context 'when whether an Item Deposit is an initial version is unknown' do
    before do
      create(:item_deposit_action, multi_item_deposit_action:, initial_version: nil)
    end

    it 'requires a version description' do
      expect(build_form).not_to be_valid
    end
  end
end
