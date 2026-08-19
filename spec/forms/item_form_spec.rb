# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ItemForm do
  subject(:item_form) do
    described_class.new(
      source_id:,
      source_id_choice:,
      source_id_prefix:,
      title:,
      admin_policy_druid: 'druid:bc123df4567',
      content_type: Cocina::Models::ObjectType.object,
      access_view: 'world',
      access_download: 'world'
    )
  end

  let(:title) { 'The Title' }
  let(:source_id) { 'new:source-id' }
  let(:source_id_choice) { ItemForm::SOURCE_ID_PROVIDED_CHOICE }
  let(:source_id_prefix) { nil }

  describe 'title' do
    context 'when present' do
      it 'is valid' do
        expect(item_form).to be_valid
      end
    end

    context 'when blank' do
      let(:title) { '' }

      it 'is not valid' do
        expect(item_form).not_to be_valid
        expect(item_form.errors[:title]).to include("can't be blank")
      end
    end

    context 'when nil' do
      let(:title) { nil }

      it 'is not valid' do
        expect(item_form).not_to be_valid
        expect(item_form.errors[:title]).to include("can't be blank")
      end
    end

    context 'when surrounded by whitespace' do
      let(:title) { '  The Title  ' }

      it 'is normalized by stripping whitespace' do
        expect(item_form.title).to eq('The Title')
      end
    end
  end

  describe 'source_id_choice' do
    context 'when "provide"' do
      let(:source_id_choice) { ItemForm::SOURCE_ID_PROVIDED_CHOICE }

      it 'is valid' do
        expect(item_form).to be_valid
      end
    end

    context 'when "generate"' do
      let(:source_id_choice) { ItemForm::SOURCE_ID_GENERATE_CHOICE }
      let(:source_id_prefix) { 'new' }

      it 'is valid' do
        expect(item_form).to be_valid
      end
    end

    context 'when not one of the allowed choices' do
      let(:source_id_choice) { 'invalid' }

      it 'is not valid' do
        expect(item_form).not_to be_valid
        expect(item_form.errors[:source_id_choice]).to include('is not included in the list')
      end
    end
  end

  describe 'source_id_prefix' do
    context 'when surrounded by whitespace and with a trailing colon' do
      let(:source_id_choice) { ItemForm::SOURCE_ID_GENERATE_CHOICE }
      let(:source_id_prefix) { '  new:  ' }

      it 'is normalized' do
        expect(item_form.source_id_prefix).to eq('new')
      end
    end

    context 'when source_id_choice is "generate" and source_id_prefix is blank' do
      let(:source_id_choice) { ItemForm::SOURCE_ID_GENERATE_CHOICE }
      let(:source_id_prefix) { '' }

      it 'is not valid' do
        expect(item_form).not_to be_valid
        expect(item_form.errors[:source_id_prefix]).to include("can't be blank")
      end
    end

    context 'when source_id_choice is "provide" and source_id_prefix is blank' do
      let(:source_id_choice) { ItemForm::SOURCE_ID_PROVIDED_CHOICE }
      let(:source_id_prefix) { '' }

      it 'is valid' do
        expect(item_form).to be_valid
      end
    end
  end

  describe 'generate_source_id' do
    context 'when source_id_choice is "generate" and source_id_prefix is present' do
      let(:source_id_choice) { ItemForm::SOURCE_ID_GENERATE_CHOICE }
      let(:source_id_prefix) { 'new' }
      let(:generated_uuid) { '123e4567-e89b-12d3-a456-426614174000' }

      before do
        allow(SecureRandom).to receive(:uuid).and_return(generated_uuid)
      end

      it 'populates source_id and changes source_id_choice to "provide"' do
        item_form.valid?
        expect(item_form.source_id).to eq("new:#{generated_uuid}")
        expect(item_form.source_id_choice).to eq(ItemForm::SOURCE_ID_PROVIDED_CHOICE)
      end
    end

    context 'when source_id_choice is "generate" and source_id_prefix is blank' do
      let(:source_id_choice) { ItemForm::SOURCE_ID_GENERATE_CHOICE }
      let(:source_id) { nil }
      let(:source_id_prefix) { '' }

      it 'does not populate source_id' do
        item_form.valid?
        expect(item_form.source_id).to be_nil
      end
    end

    context 'when source_id_choice is "provide"' do
      let(:source_id_choice) { ItemForm::SOURCE_ID_PROVIDED_CHOICE }

      it 'does not change source_id' do
        expect { item_form.valid? }.not_to(change(item_form, :source_id))
      end
    end
  end

  describe 'release_tags' do
    context 'when valid' do
      it 'is valid' do
        expect(item_form).to be_valid
      end
    end

    context 'when invalid' do
      before do
        item_form.release_tags.release_choice = ReleaseTagsForm::RELEASE_TO_TARGETS
      end

      it 'is not valid' do
        expect(item_form).not_to be_valid
        expect(item_form.release_tags.errors[:release_targets]).to include('At least one target must be selected')
      end
    end
  end

  describe '.permitted_params' do
    it 'includes nested release_tags_attributes' do
      expect(described_class.permitted_params).to include(
        release_tags_attributes: ReleaseTagsForm.permitted_params
      )
    end
  end

  describe 'populate_description_hash' do
    context 'when title is present' do
      it 'sets description_hash from title on validation' do
        item_form.valid?
        expect(item_form.description_hash).to eq(title: [{ value: 'The Title' }])
      end
    end

    context 'when title is blank' do
      let(:title) { nil }

      it 'does not overwrite description_hash' do
        expect { item_form.valid? }.not_to(change(item_form, :description_hash))
      end
    end
  end
end
