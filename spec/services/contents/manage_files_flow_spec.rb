# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Contents::ManageFilesFlow do
  subject(:manage_files_flow) { described_class.new(content:, agreement:) }

  let(:content) { create(:content, :mutable, druid: 'druid:bc123df4567', step:) }
  let(:step) { 'details' }
  let(:agreement) { false }
  let(:form) { instance_double(ContentsItemForm, save_item_details!: nil) }

  before do
    allow(StructureFilesJob).to receive(:perform_later)
  end

  describe '#steps' do
    it 'has the item details step for an item' do
      expect(manage_files_flow.steps).to eq(%w[details files structure deposit])
    end

    context 'when an agreement' do
      let(:agreement) { true }

      it 'has no item details step' do
        expect(manage_files_flow.steps).to eq(%w[files structure deposit])
      end
    end
  end

  describe '#current_step' do
    context 'when an agreement on the default step' do
      let(:agreement) { true }

      it 'is the first step' do
        expect(manage_files_flow.current_step).to eq('files')
      end
    end
  end

  describe '#next!' do
    it 'saves the item details on the next step' do
      manage_files_flow.next!(form)

      expect(form).to have_received(:save_item_details!).with(step: 'files')
      expect(StructureFilesJob).not_to have_received(:perform_later)
    end

    context 'when leaving the add and edit files step without resources' do
      let(:step) { 'files' }

      it 'structures the files' do
        manage_files_flow.next!(form)

        expect(form).to have_received(:save_item_details!).with(step: 'structure')
        expect(StructureFilesJob).to have_received(:perform_later).with(content:, append: false)
      end
    end
  end

  describe '#current_step_complete?' do
    context 'when on the item details step' do
      it 'is complete when the item details are valid' do
        expect(manage_files_flow.current_step_complete?(instance_double(ContentsItemForm, item_details_valid?: true)))
          .to be true
      end

      it 'is incomplete when the item details are invalid' do
        expect(manage_files_flow.current_step_complete?(instance_double(ContentsItemForm, item_details_valid?: false)))
          .to be false
      end
    end

    context 'when on the add and edit files step' do
      let(:step) { 'files' }

      it 'is incomplete without files' do
        expect(manage_files_flow.current_step_complete?(form)).to be false
      end

      it 'is complete with a file' do
        create(:content_file_binary, content:)

        expect(manage_files_flow.current_step_complete?(form)).to be true
      end
    end

    context 'when on the structure step' do
      let(:step) { 'structure' }

      it 'is complete' do
        expect(manage_files_flow.current_step_complete?(form)).to be true
      end
    end
  end

  describe '#previous!' do
    let(:step) { 'deposit' }

    it 'saves the item details on the previous step' do
      manage_files_flow.previous!(form)

      expect(form).to have_received(:save_item_details!).with(step: 'structure')
    end
  end

  describe '#go_to_deposit_errors!' do
    let(:step) { 'files' }
    let(:form) { ContentsItemForm.new }

    it 'moves to the step with the fields of the first error that depositing finds' do
      allow(form).to receive(:valid?).with(:deposit) do
        form.errors.add(:content, 'is invalid')
        false
      end

      manage_files_flow.go_to_deposit_errors!(form)

      expect(content.reload.step).to eq('structure')
    end

    it 'stays on the step when depositing finds no errors' do
      allow(form).to receive(:valid?).with(:deposit).and_return(true)

      manage_files_flow.go_to_deposit_errors!(form)

      expect(content.reload.step).to eq('files')
    end
  end

  describe '#go_to_first_error!' do
    let(:step) { 'deposit' }
    let(:errors) { ActiveModel::Errors.new(ContentsItemForm.new) }

    it 'moves to the step with the fields of the first error' do
      errors.add(:version_description, :blank)
      errors.add(:content, 'is invalid')

      manage_files_flow.go_to_first_error!(errors)

      expect(content.reload.step).to eq('structure')
    end

    it 'moves to the item details step for an error on an item detail' do
      errors.add(:access, 'is not valid')

      manage_files_flow.go_to_first_error!(errors)

      expect(content.reload.step).to eq('details')
    end
  end
end
