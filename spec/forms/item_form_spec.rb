# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ItemForm do
  subject(:item_form) do
    described_class.new(
      source_id:,
      source_id_choice:,
      source_id_prefix:,
      title:,
      description_choice:,
      catalog_record_id:,
      description_csv_file:,
      apo_druid: 'druid:bc123df4567',
      content_type: Cocina::Models::ObjectType.object,
      access_view: 'world',
      access_download: 'world'
    )
  end

  let(:title) { 'The Title' }
  let(:description_choice) { ItemForm::DESCRIPTION_TITLE_CHOICE }
  let(:catalog_record_id) { nil }
  let(:description_csv_file) { nil }
  let(:source_id) { 'new:source-id' }
  let(:source_id_choice) { ItemForm::SOURCE_ID_PROVIDED_CHOICE }
  let(:source_id_prefix) { nil }

  before do
    allow(Sdr::Repository).to receive(:source_id_exists?).and_return(false)
  end

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

    context 'when blank and description choice is not title' do
      let(:title) { nil }
      let(:description_choice) { ItemForm::DESCRIPTION_CATALOG_ID_CHOICE }
      let(:catalog_record_id) { 'in11403803' }

      it 'is valid' do
        expect(item_form).to be_valid
      end
    end

    context 'when surrounded by whitespace' do
      let(:title) { '  The Title  ' }

      it 'is normalized by stripping whitespace' do
        expect(item_form.title).to eq('The Title')
      end
    end
  end

  describe 'description_csv_file' do
    let(:description_choice) { ItemForm::DESCRIPTION_SPREADSHEET_CHOICE }
    let(:title) { nil }
    let(:description_csv_file) { fixture_file_upload('item_description.csv', 'text/csv') }

    context 'when a valid spreadsheet is provided' do
      it 'is valid and populates the description from the spreadsheet' do
        expect(item_form).to be_valid
        expect(item_form.description_hash[:title].first).to include(value: 'A spreadsheet title')
        expect(item_form.description_hash[:note].first).to include(value: 'A note', type: 'summary')
      end

      it 'does not include a purl, which a registration request does not allow' do
        item_form.valid?
        expect(item_form.description_hash).not_to have_key(:purl)
      end
    end

    context 'when blank' do
      let(:description_csv_file) { nil }

      it 'is not valid' do
        expect(item_form).not_to be_valid
        expect(item_form.errors[:description_csv_file]).to eq(["can't be blank"])
      end
    end

    context 'when blank and description choice is not spreadsheet' do
      let(:description_choice) { ItemForm::DESCRIPTION_TITLE_CHOICE }
      let(:title) { 'The Title' }
      let(:description_csv_file) { nil }

      it 'is valid' do
        expect(item_form).to be_valid
      end
    end

    context 'when the spreadsheet is not valid' do
      let(:description_csv_file) { fixture_file_upload('item_description_invalid.csv', 'text/csv') }

      it 'is not valid and does not populate the description' do
        expect(item_form).not_to be_valid
        expect(item_form.errors[:description_csv_file]).to eq(['Title column not found.'])
        expect(item_form.description_hash).to eq(title: [{ value: ':auto' }])
      end
    end

    context 'when the spreadsheet has more than one row' do
      let(:description_csv_file) { fixture_file_upload('item_description_multiple_rows.csv', 'text/csv') }

      it 'is not valid' do
        expect(item_form).not_to be_valid
        expect(item_form.errors[:description_csv_file]).to eq(['Only one row of description is allowed.'])
      end
    end

    context 'when the spreadsheet has no rows' do
      let(:description_csv_file) { fixture_file_upload('item_description_no_rows.csv', 'text/csv') }

      it 'is not valid' do
        expect(item_form).not_to be_valid
        expect(item_form.errors[:description_csv_file]).to eq(['Description row not found.'])
      end
    end

    context 'when the spreadsheet has a title column but no title value' do
      let(:description_csv_file) { fixture_file_upload('item_description_no_title_value.csv', 'text/csv') }

      it 'is not valid and does not populate the description' do
        expect(item_form).not_to be_valid
        expect(item_form.errors[:description_csv_file]).to eq(['Title value not found.'])
        expect(item_form.description_hash).to eq(title: [{ value: ':auto' }])
      end
    end

    context 'when the description cannot be imported' do
      before do
        allow(DescriptiveCsv::Import).to receive(:import).and_return(Dry::Monads::Failure(['Nope.']))
      end

      it 'is not valid' do
        expect(item_form).not_to be_valid
        expect(item_form.errors[:description_csv_file]).to eq(['Nope.'])
      end
    end
  end

  describe 'catalog_record_id' do
    let(:description_choice) { ItemForm::DESCRIPTION_CATALOG_ID_CHOICE }
    let(:title) { nil }

    context 'when present' do
      let(:catalog_record_id) { 'in11403803' }

      it 'is valid' do
        expect(item_form).to be_valid
      end
    end

    context 'when blank' do
      it 'is not valid' do
        expect(item_form).not_to be_valid
        expect(item_form.errors[:catalog_record_id]).to include("can't be blank")
      end
    end

    context 'when blank and description choice is not catalog id' do
      let(:description_choice) { ItemForm::DESCRIPTION_TITLE_CHOICE }
      let(:title) { 'The Title' }

      it 'is valid' do
        expect(item_form).to be_valid
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

  describe 'source_id' do
    context 'when present and does not already exist' do
      it 'is valid' do
        expect(item_form).to be_valid
        expect(Sdr::Repository).to have_received(:source_id_exists?).with(source_id:)
      end
    end

    context 'when present and already exists' do
      before do
        allow(Sdr::Repository).to receive(:source_id_exists?).and_return(true)
      end

      it 'is not valid' do
        expect(item_form).not_to be_valid
        expect(item_form.errors[:source_id]).to include('already exists')
      end
    end

    context 'when blank' do
      let(:source_id) { nil }

      it 'does not check for existence' do
        item_form.valid?
        expect(Sdr::Repository).not_to have_received(:source_id_exists?)
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

  describe 'collection_druids' do
    subject(:item_form) { described_class.new(collection_druids: ['', 'druid:bc123df4567']) }

    it 'removes the blank value submitted by the multiple select' do
      expect(item_form.collection_druids).to eq(['druid:bc123df4567'])
    end
  end

  describe 'when built from a cocina object' do
    subject(:item_form) { described_class.build_from_cocina_object(cocina_object) }

    let(:cocina_object) { build(:dro_with_metadata, collection_ids: %w[druid:bc123df4567 druid:gh456jk7890]) }

    it 'is not changed' do
      expect(item_form).not_to be_changed
    end

    context 'when collections are updated' do
      before { item_form.update(collection_druids: ['', 'druid:mn789pq0123']) }

      it 'is changed' do
        expect(item_form).to be_changed
      end
    end

    context 'when all collections are removed' do
      before { item_form.update(collection_druids: ['']) }

      it 'removes the collections' do
        expect(item_form.collection_druids).to be_empty
        expect(item_form).to be_changed
      end
    end

    context 'when saved after the collections are updated' do
      before do
        allow(Sdr::Repository).to receive(:update)
        # A title is required when the description choice is title.
        item_form.title = 'The Title'
        item_form.update(collection_druids: ['', 'druid:mn789pq0123'])
      end

      it 'updates the object with the new collections' do
        item_form.save!(user_name: 'jcoyne85')

        expect(Sdr::Repository).to have_received(:update)
          .with(cocina_object: having_attributes(structural: having_attributes(isMemberOf: ['druid:mn789pq0123'])),
                user_name: 'jcoyne85', description: nil)
      end
    end
  end

  describe 'with_embargo' do
    context 'when not provided and the embargo release date is present' do
      subject(:item_form) do
        described_class.new(
          source_id:,
          source_id_choice:,
          source_id_prefix:,
          title:,
          apo_druid: 'druid:bc123df4567',
          content_type: Cocina::Models::ObjectType.object,
          access_view: 'world',
          access_download: 'world',
          embargo_release_date: Time.zone.parse('2030-01-01'),
          embargo_view: 'location-based',
          embargo_download: 'location-based',
          embargo_location: 'spec'
        )
      end

      it 'defaults to true' do
        expect(item_form.with_embargo).to be(true)
      end
    end

    context 'when not provided and the embargo release date is blank' do
      it 'defaults to false' do
        expect(item_form.with_embargo).to be(false)
      end
    end
  end

  describe 'embargo_release_date' do
    context 'when with_embargo is true and the embargo release date is blank' do
      before do
        item_form.with_embargo = true
      end

      it 'is not valid' do
        expect(item_form).not_to be_valid
        expect(item_form.errors[:embargo_release_date]).to include("can't be blank")
      end
    end

    context 'when with_embargo is false and the embargo release date is blank' do
      before do
        item_form.with_embargo = false
      end

      it 'is valid' do
        expect(item_form).to be_valid
      end
    end
  end

  describe 'nullify_embargo_access_rights' do
    subject(:item_form) do
      described_class.new(
        source_id:,
        source_id_choice:,
        source_id_prefix:,
        title:,
        apo_druid: 'druid:bc123df4567',
        content_type: Cocina::Models::ObjectType.object,
        access_view: 'world',
        access_download: 'world',
        embargo_release_date: Time.zone.parse('2030-01-01'),
        embargo_view: 'location-based',
        embargo_download: 'location-based',
        embargo_location: 'spec'
      )
    end

    context 'when with_embargo is false' do
      before do
        item_form.with_embargo = false
      end

      it 'nullifies the embargo fields on validation' do
        expect(item_form).to be_valid
        expect(item_form.embargo_release_date).to be_nil
        expect(item_form.embargo_view).to be_nil
        expect(item_form.embargo_download).to be_nil
        expect(item_form.embargo_location).to be_nil
      end
    end

    context 'when with_embargo is true' do
      it 'does not nullify the embargo fields on validation' do
        expect(item_form).to be_valid
        expect(item_form.embargo_release_date).to eq(Time.zone.parse('2030-01-01'))
        expect(item_form.embargo_view).to eq('location-based')
        expect(item_form.embargo_download).to eq('location-based')
        expect(item_form.embargo_location).to eq('spec')
      end
    end
  end

  describe 'populate_folio_catalog_link' do
    let(:title) { nil }
    let(:catalog_record_id) { 'in11403803' }

    context 'when description choice is catalog id' do
      let(:description_choice) { ItemForm::DESCRIPTION_CATALOG_ID_CHOICE }

      it 'builds a folio catalog link and requests a catalog refresh on validation' do
        item_form.valid?
        expect(item_form.folio_catalog_links.map(&:catalog_record_id)).to eq(['in11403803'])
        expect(item_form.catalog_link_refresh).to be(true)
      end
    end

    context 'when description choice is not catalog id' do
      let(:description_choice) { ItemForm::DESCRIPTION_SPREADSHEET_CHOICE }

      it 'does not build a folio catalog link' do
        item_form.valid?
        expect(item_form.folio_catalog_links).to be_empty
        expect(item_form.catalog_link_refresh).to be(false)
      end
    end
  end

  describe 'populate_description_hash_from_title' do
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

    context 'when description choice is not title' do
      let(:description_choice) { ItemForm::DESCRIPTION_CATALOG_ID_CHOICE }

      it 'does not overwrite description_hash' do
        expect { item_form.valid? }.not_to(change(item_form, :description_hash))
      end
    end
  end
end
