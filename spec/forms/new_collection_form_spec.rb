# frozen_string_literal: true

require 'rails_helper'

RSpec.describe NewCollectionForm do
  subject(:new_collection_form) do
    described_class.new(title:, description_choice:, catalog_record_id:, access_view:, apo_druid: 'druid:hv992ry2431',
                        other_tags_attributes: { '0' => { tag: 'Some : Tag' } },
                        release_tags_attributes: { searchworks_target: 'collection' })
  end

  let(:title) { 'My collection' }
  let(:description_choice) { 'title' }
  let(:catalog_record_id) { nil }
  let(:access_view) { 'world' }

  describe '.permitted_params' do
    it 'does not permit attributes without a field on the collection form' do
      expect(described_class.permitted_params)
        .not_to include(:source_id, :use_and_reproduction_statement, :license, :copyright, :catalog_link_refresh,
                        :catalog_link_part_label, :catalog_link_sort_key, { description_hash: [] })
    end
  end

  describe 'validation' do
    context 'when entering a title' do
      it 'is valid without a source id' do
        expect(new_collection_form).to be_valid
      end
    end

    context 'when entering a blank title' do
      let(:title) { '' }

      it 'is invalid' do
        expect(new_collection_form).not_to be_valid
        expect(new_collection_form.errors[:title]).to include("can't be blank")
      end
    end

    context 'when retrieving the description from FOLIO without a FOLIO Instance HRID' do
      let(:description_choice) { 'catalog_id' }
      let(:title) { nil }

      it 'is invalid' do
        expect(new_collection_form).not_to be_valid
        expect(new_collection_form.errors[:catalog_record_id]).to include("can't be blank")
      end
    end

    context 'when the description choice is not title or FOLIO' do
      let(:description_choice) { 'spreadsheet' }

      it 'is invalid' do
        expect(new_collection_form).not_to be_valid
        expect(new_collection_form.errors[:description_choice]).to include('is not included in the list')
      end
    end

    context 'when the APO is one of the selectable APOs' do
      before { new_collection_form.selectable_apo_druids = ['druid:hv992ry2431'] }

      it 'is valid' do
        expect(new_collection_form).to be_valid
      end
    end

    context 'when the APO is not one of the selectable APOs' do
      before { new_collection_form.selectable_apo_druids = ['druid:bc123df4567'] }

      it 'is invalid' do
        expect(new_collection_form).not_to be_valid
        expect(new_collection_form.errors[:apo_druid]).to include('must be an APO you can edit')
      end
    end

    context 'when the view access is not world or dark' do
      let(:access_view) { 'stanford' }

      it 'is invalid' do
        expect(new_collection_form).not_to be_valid
        expect(new_collection_form.errors[:access_view]).to include('is not included in the list')
      end
    end
  end

  describe '#create!' do
    let(:registered_cocina_object) { build(:collection_with_metadata, id: 'druid:xz987wv6543') }

    before do
      allow(Sdr::Repository).to receive(:register).and_return(registered_cocina_object)
      allow(Sdr::Repository).to receive(:create_release_tag)
      allow(Sdr::Repository).to receive(:accession)
    end

    it 'registers the collection, creates its release tags, and then starts accessioning' do
      new_collection_form.create!(user_name: 'jcoyne')

      expect(Sdr::Repository).to have_received(:register).ordered do |args|
        request_cocina_object = args[:request_cocina_object]
        expect(request_cocina_object.type).to eq(Cocina::Models::ObjectType.collection)
        expect(request_cocina_object.description.title.first.value).to eq('My collection')
        expect(request_cocina_object.administrative.hasAdminPolicy).to eq('druid:hv992ry2431')
        expect(request_cocina_object.access.view).to eq('world')
        expect(args[:tags]).to eq(['Some : Tag'])
      end
      expect(Sdr::Repository).to have_received(:create_release_tag)
        .with(druid: 'druid:xz987wv6543', user_name: 'jcoyne', release_target: 'Searchworks', release: true,
              release_what: 'collection').ordered
      expect(Sdr::Repository).to have_received(:accession)
        .with(cocina_object: registered_cocina_object, user_name: 'jcoyne').ordered
    end

    context 'when retrieving the description from FOLIO' do
      let(:description_choice) { 'catalog_id' }
      let(:catalog_record_id) { 'a12345' }
      let(:title) { nil }

      it 'registers the collection with a refreshing FOLIO catalog link' do
        new_collection_form.create!(user_name: 'jcoyne')

        expect(Sdr::Repository).to have_received(:register) do |args|
          expect(args[:request_cocina_object].identification.catalogLinks.map(&:to_h))
            .to eq([{ catalog: 'folio', catalogRecordId: 'a12345', refresh: true }])
        end
      end
    end
  end
end
