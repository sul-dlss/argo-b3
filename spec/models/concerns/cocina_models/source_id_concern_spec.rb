# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CocinaModels::SourceIdConcern do
  # ItemForm and CocinaModels::Dro are used as representative models that include the concern.
  # ItemForm is never persisted; CocinaModels::Dro covers the persisted (edit) cases.
  subject(:item_form) do
    ItemForm.new(
      source_id:,
      title: 'The Title',
      apo_druid: 'druid:bc123df4567',
      content_type: Cocina::Models::ObjectType.object,
      access_view: 'world',
      access_download: 'world'
    )
  end

  let(:source_id) { 'sul:1234' }

  before do
    allow(Sdr::Repository).to receive(:source_id_exists?).and_return(false)
  end

  describe 'uniqueness of source_id' do
    context 'when the source_id does not already exist' do
      it 'is valid and checks for existence' do
        expect(item_form).to be_valid
        expect(Sdr::Repository).to have_received(:source_id_exists?).with(source_id:)
      end
    end

    context 'when the source_id already exists' do
      before do
        allow(Sdr::Repository).to receive(:source_id_exists?).and_return(true)
      end

      it 'is not valid' do
        expect(item_form).not_to be_valid
        expect(item_form.errors[:source_id]).to include('already exists')
      end
    end

    context 'when the source_id is malformed' do
      let(:source_id) { 'no-colon' }

      it 'does not check for existence' do
        expect(item_form).not_to be_valid
        expect(item_form.errors[:source_id]).to include('is invalid')
        expect(Sdr::Repository).not_to have_received(:source_id_exists?)
      end
    end

    context 'when the source_id is blank' do
      let(:source_id) { nil }

      it 'does not check for existence' do
        expect(item_form).not_to be_valid
        expect(item_form.errors[:source_id]).to include("can't be blank")
        expect(Sdr::Repository).not_to have_received(:source_id_exists?)
      end
    end

    # A persisted model would find its own source_id in the repository, so the check is skipped
    # unless the source_id has been changed.
    context 'when the model is persisted and the source_id is unchanged' do
      subject(:dro) { CocinaModels::Dro.build_from_cocina_object(cocina_object) }

      let(:cocina_object) { build(:dro_with_metadata, source_id:) }

      it 'does not check for existence' do
        expect(dro).to be_valid
        expect(Sdr::Repository).not_to have_received(:source_id_exists?)
      end
    end

    context 'when the model is persisted and the source_id has been changed' do
      subject(:dro) { CocinaModels::Dro.build_from_cocina_object(cocina_object) }

      let(:cocina_object) { build(:dro_with_metadata, source_id:) }
      let(:new_source_id) { 'sul:5678' }

      before do
        dro.source_id = new_source_id
      end

      it 'checks for existence of the new source_id' do
        expect(dro).to be_valid
        expect(Sdr::Repository).to have_received(:source_id_exists?).with(source_id: new_source_id)
      end

      context 'when the new source_id belongs to another object' do
        before do
          allow(Sdr::Repository).to receive(:source_id_exists?).and_return(true)
        end

        it 'is not valid' do
          expect(dro).not_to be_valid
          expect(dro.errors[:source_id]).to include('already exists')
        end
      end
    end
  end
end
