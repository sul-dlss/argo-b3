# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Contents::ManageFilesFlow do
  subject(:manage_files_flow) { described_class.new(content:, agreement:) }

  let(:content) { create(:content, :mutable, druid: 'druid:bc123df4567', step:) }
  let(:step) { 'details' }
  let(:agreement) { false }
  let(:form) { ContentsItemForm.new(content_type: Cocina::Models::ObjectType.book) }

  before do
    allow(StructureFilesJob).to receive(:perform_later)
  end

  describe '.reset!' do
    let(:content) do
      create(:content, :mutable, druid: 'druid:bc123df4567', step: 'deposit',
                                 content_type: Cocina::Models::ObjectType.book, version_description: 'Added pages',
                                 perform_ocr: true)
    end

    it 'returns to the first step and clears the item details, keeping the text extraction settings' do
      described_class.reset!(content:)

      expect(content.reload).to have_attributes(step: 'details', content_type: nil, version_description: nil,
                                                perform_ocr: true)
    end
  end

  describe '#take_structuring_result!' do
    context 'when structuring failed' do
      let(:content) { create(:content, :mutable, druid: 'druid:bc123df4567', structuring_state: 'structuring_failed') }

      it 'returns the result once' do
        expect(manage_files_flow.take_structuring_result!).to eq('structuring_failed')
        expect(content.reload).to be_structuring_not_in_progress
        expect(manage_files_flow.take_structuring_result!).to be_nil
      end
    end

    context 'when structuring' do
      let(:content) { create(:content, :mutable, druid: 'druid:bc123df4567', structuring_state: 'structuring') }

      it 'is nil' do
        expect(manage_files_flow.take_structuring_result!).to be_nil
        expect(content.reload).to be_structuring
      end
    end
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

  describe '#open_on!' do
    let(:step) { 'deposit' }

    context 'when opening on the first step' do
      it 'opens on item details' do
        manage_files_flow.open_on!('first')

        expect(content.reload.step).to eq('details')
      end
    end

    context 'when opening on the first step of an agreement' do
      let(:agreement) { true }

      it 'opens on add and edit files' do
        manage_files_flow.open_on!('first')

        expect(content.reload.step).to eq('files')
      end
    end

    context 'when opening on structure files with structured files' do
      before do
        create(:content_file, content_file_set: create(:content_file_set, content:))
      end

      it 'opens on structure files without structuring' do
        manage_files_flow.open_on!('structure')

        expect(content.reload.step).to eq('structure')
        expect(StructureFilesJob).not_to have_received(:perform_later)
      end
    end

    context 'when opening on structure files with files not in a resource' do
      before do
        create(:content_file, content_file_set: create(:content_file_set, content:))
        create(:content_file_binary, content:, filepath: 'image2.tif', basename: 'image2')
      end

      it 'opens on add and edit files without appending the files, so that the user chooses how to structure them' do
        manage_files_flow.open_on!('structure')

        expect(content.reload.step).to eq('files')
        expect(StructureFilesJob).not_to have_received(:perform_later)
      end
    end

    context 'when opening while discovering files' do
      let(:content) do
        create(:content, :mutable, druid: 'druid:bc123df4567', step: 'files', mount_state: 'discovering')
      end

      it 'keeps the saved step' do
        manage_files_flow.open_on!('first')

        expect(content.reload.step).to eq('files')
      end
    end

    context 'when opening on structure files without files' do
      it 'opens on add and edit files' do
        manage_files_flow.open_on!('structure')

        expect(content.reload.step).to eq('files')
        expect(StructureFilesJob).not_to have_received(:perform_later)
      end
    end
  end

  describe '#next!' do
    it 'saves the item details on the next step' do
      manage_files_flow.next!(form)

      expect(content.reload).to have_attributes(step: 'files', content_type: Cocina::Models::ObjectType.book)
      expect(StructureFilesJob).not_to have_received(:perform_later)
    end

    context 'when leaving the add and edit files step without resources' do
      let(:step) { 'files' }

      it 'structures the files' do
        manage_files_flow.next!(form)

        expect(content.reload.step).to eq('structure')
        expect(StructureFilesJob).to have_received(:perform_later).with(content:, append: false)
      end
    end

    context 'when leaving the add and edit files step with resources and files not in a resource' do
      let(:step) { 'files' }

      before do
        create(:content_file, content_file_set: create(:content_file_set, content:))
        create(:content_file_binary, content:, filepath: 'image2.tif', basename: 'image2')
      end

      it 'appends the files' do
        manage_files_flow.next!(form)

        expect(StructureFilesJob).to have_received(:perform_later).with(content:, append: true)
      end

      it 'rebuilds the resources when chosen' do
        manage_files_flow.next!(form, rebuild: true)

        expect(content.reload.step).to eq('structure')
        expect(StructureFilesJob).to have_received(:perform_later).with(content:, append: false)
      end
    end
  end

  describe '.new_files_question?' do
    it 'is false without resources' do
      create(:content_file_binary, content:)

      expect(described_class.new_files_question?(content:)).to be false
    end

    it 'is false when every file is in a resource' do
      create(:content_file, content_file_set: create(:content_file_set, content:))

      expect(described_class.new_files_question?(content:)).to be false
    end

    it 'is true with resources and a file not in a resource' do
      create(:content_file, content_file_set: create(:content_file_set, content:))
      create(:content_file_binary, content:, filepath: 'image2.tif', basename: 'image2')

      expect(described_class.new_files_question?(content:)).to be true
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

      expect(content.reload).to have_attributes(step: 'structure', content_type: Cocina::Models::ObjectType.book)
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
