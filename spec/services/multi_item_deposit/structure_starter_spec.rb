# frozen_string_literal: true

require 'rails_helper'

RSpec.describe MultiItemDeposit::StructureStarter do
  let(:multi_item_deposit_action) do
    create(:multi_item_deposit_action, step: 'structure', structuring_completed_at: 1.day.ago)
  end
  let(:structure_form) do
    instance_double(MultiItemDeposit::StructureForm,
                    multi_item_deposit_action_attributes: { perform_ocr: true, ocr_languages: ['English'] })
  end
  let!(:item_deposit_actions) do
    [create(:item_deposit_action, multi_item_deposit_action:, druid: 'druid:bc123df4567'),
     create(:item_deposit_action, multi_item_deposit_action:, druid: 'druid:cd234fg5678')]
  end

  # The test database has no queue tables, so a verifying double (which loads the schema) cannot be used.
  # The block enqueues to the test adapter.
  let(:batch_class) { double('SolidQueue::Batch') } # rubocop:disable RSpec/VerifiedDoubles

  before do
    stub_const('SolidQueue::Batch', batch_class)
    allow(batch_class).to receive(:enqueue).and_yield
  end

  it 'saves the structure settings and starts structuring' do
    described_class.call(multi_item_deposit_action:, structure_form:)

    expect(multi_item_deposit_action.reload).to have_attributes(
      perform_ocr: true, ocr_languages: ['English'], structuring_state: 'structuring',
      structuring_started_at: be_within(1.second).of(Time.current), structuring_completed_at: nil
    )
  end

  it 'enqueues a batch of structure jobs' do
    described_class.call(multi_item_deposit_action:, structure_form:)

    expect(batch_class).to have_received(:enqueue)
      .with(on_finish: an_instance_of(MultiItemDeposit::StructureFinishJob)
                         .and(having_attributes(arguments: [{ multi_item_deposit_action: }])))
    item_deposit_actions.each do |item_deposit_action|
      expect(MultiItemDeposit::StructureJob).to have_been_enqueued.with(item_deposit_action:)
    end
  end
end
