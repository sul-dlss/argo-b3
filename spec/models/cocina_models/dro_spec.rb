# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CocinaModels::Dro do
  include ActiveModel::Lint::Tests
  include ActiveSupport::Testing::Assertions

  subject(:dro) { described_class.new(cocina_object) }

  let(:cocina_object) { build(:dro_with_metadata) }

  describe '#initialize' do
    context 'with a valid Cocina::Models::DROWithMetadata' do
      it 'initializes with a Cocina::Models::DROWithMetadata' do
        expect(dro.external_identifier).to eq(cocina_object.externalIdentifier)
        expect(dro.source_id).to eq(cocina_object.identification.sourceId)
      end
    end

    context 'with an invalid object' do
      let(:cocina_object) { 'invalid' }

      it 'raises an error if initialized with an invalid object' do
        expect { dro }.to raise_error(ArgumentError)
      end
    end

    context 'with a folio catalog link' do
      let(:cocina_object) { build(:dro_with_metadata, folio_instance_hrids: ['in11403803']) }

      it 'initializes folio catalog links from the cocina object' do
        expect(dro.folio_catalog_links.count).to eq(1)
        expect(dro.folio_catalog_links.first.catalog_record_id).to eq('in11403803')
      end
    end
  end

  describe '#update' do
    let(:new_source_id) { 'new-source-id' }
    let(:attributes) { { source_id: new_source_id } }

    it 'updates the attributes of the model' do
      dro.update(attributes)
      expect(dro.source_id).to eq(new_source_id)
    end

    context 'when updating external_identifier' do
      let(:new_external_identifier) { 'new-external-identifier' }
      let(:attributes) { { external_identifier: new_external_identifier } }

      it 'does not allow updating external_identifier' do
        expect { dro.update(attributes) }.to raise_error(NoMethodError)
      end
    end

    context 'when updating with folio catalog link attributes' do
      let(:attributes) { { folio_catalog_links_attributes: [{ catalog_record_id: 'in11403803' }] } }

      it 'updates the folio catalog links' do
        dro.update(attributes)
        expect(dro.folio_catalog_links.first.catalog_record_id).to eq('in11403803')
      end
    end
  end

  describe '#save!' do
    let(:user_name) { 'test_user' }
    let(:description) { 'Changed source id' }

    before do
      allow(Sdr::Repository).to receive(:update)
    end

    context 'with valid and changed attributes' do
      let(:new_source_id) { 'changed:source-id' }

      before do
        dro.source_id = new_source_id
      end

      it 'saves the model successfully' do
        dro.save!(user_name:, description:)
        expect(Sdr::Repository).to have_received(:update) do |args|
          new_cocina_object = args[:cocina_object]
          expect(new_cocina_object).to be_a(Cocina::Models::DROWithMetadata)
          expect(new_cocina_object.lock).to eq(cocina_object.lock)
          expect(new_cocina_object.identification.sourceId).to eq(new_source_id)

          expect(args[:user_name]).to eq(user_name)
          expect(args[:description]).to eq(description)
        end
        expect(dro.changed?).to be false
      end
    end

    context 'with invalid attributes' do
      before do
        dro.source_id = 'invalid-source-id'
      end

      it 'raises a validation error' do
        expect { dro.save!(user_name:, description:) }.to raise_error(ActiveModel::ValidationError)
      end
    end

    context 'when no attributes have changed' do
      it 'does not attempt to save' do
        dro.save!(user_name:, description:)
        expect(Sdr::Repository).not_to have_received(:update)
      end
    end

    context 'when saving with a folio catalog link' do
      let(:cocina_object) { build(:dro_with_metadata, folio_instance_hrids: ['in11403803']) }

      before do
        dro.source_id = 'changed:source-id'
      end

      it 'saves the model including the folio catalog link' do
        dro.save!(user_name:, description:)
        expect(Sdr::Repository).to have_received(:update) do |args|
          new_cocina_object = args[:cocina_object]
          folio_link = new_cocina_object.identification.catalogLinks.find { |link| link.catalog == 'folio' }
          expect(folio_link.catalogRecordId).to eq('in11403803')
        end
      end
    end
  end

  describe 'change tracking' do
    it 'tracks changes to attributes' do
      expect(dro.changed?).to be false
      expect(dro.source_id_changed?).to be false
      dro.source_id = 'changed-source-id'
      expect(dro.changed?).to be true
      expect(dro.source_id_changed?).to be true
    end

    it 'tracks changes to a nested folio catalog link attribute' do
      cocina_object_with_link = build(:dro_with_metadata, folio_instance_hrids: ['in11403803'])
      dro_with_link = described_class.new(cocina_object_with_link)
      folio_link = dro_with_link.folio_catalog_links.first
      expect(folio_link.changed?).to be false
      folio_link.catalog_record_id = 'in99999999'
      expect(folio_link.changed?).to be true
    end
  end

  describe 'type predicates' do
    it 'returns true for #dro?' do
      expect(dro.dro?).to be true
    end

    it 'returns false for #collection?' do
      expect(dro.collection?).to be false
    end

    it 'returns false for #admin_policy?' do
      expect(dro.admin_policy?).to be false
    end
  end

  describe 'validate access' do
    let(:access_view) { 'world' }
    let(:access_download) { 'none' }
    let(:access_location) { nil }

    before do
      dro.access_view = access_view
      dro.access_download = access_download
      dro.access_location = access_location
    end

    context 'when access is dark' do
      let(:access_view) { 'dark' }

      it 'is valid' do
        expect(dro).to be_valid
      end
    end

    context 'when access is citation-only' do
      let(:access_view) { 'citation-only' }

      it 'is valid' do
        expect(dro).to be_valid
      end
    end

    context 'when view access is location-based and download is none' do
      let(:access_view) { 'location-based' }
      let(:access_location) { Constants::ACCESS_LOCATIONS.first }

      it 'is valid' do
        expect(dro).to be_valid
      end
    end

    context 'when view access is location-based and download is location-based' do
      let(:access_view) { 'location-based' }
      let(:access_download) { 'location-based' }
      let(:access_location) { Constants::ACCESS_LOCATIONS.first }

      it 'is valid' do
        expect(dro).to be_valid
      end
    end

    context 'when download access is location-based with stanford view' do
      let(:access_view) { 'stanford' }
      let(:access_download) { 'location-based' }
      let(:access_location) { Constants::ACCESS_LOCATIONS.first }

      it 'is valid' do
        expect(dro).to be_valid
      end
    end

    context 'when download access is location-based with world view' do
      let(:access_download) { 'location-based' }
      let(:access_location) { Constants::ACCESS_LOCATIONS.first }

      it 'is valid' do
        expect(dro).to be_valid
      end
    end

    context 'when access is stanford' do
      let(:access_view) { 'stanford' }
      let(:access_download) { 'stanford' }

      it 'is valid' do
        expect(dro).to be_valid
      end
    end

    context 'when access is world and download is stanford' do
      let(:access_download) { 'stanford' }

      it 'is valid' do
        expect(dro).to be_valid
      end
    end

    context 'when access is world and download is world' do
      let(:access_download) { 'world' }

      it 'is valid' do
        expect(dro).to be_valid
      end
    end

    context 'when access combination is invalid' do
      let(:access_view) { 'stanford' }
      let(:access_download) { 'none' }

      it 'is not valid and adds an access error' do
        expect(dro).not_to be_valid
        expect(dro.errors[:access]).to include('is not valid')
      end
    end

    context 'when location is required but missing' do
      let(:access_view) { 'location-based' }

      it 'is not valid and adds an access error' do
        expect(dro).not_to be_valid
        expect(dro.errors[:access]).to include('is not valid')
      end
    end

    context 'when location is invalid' do
      let(:access_view) { 'location-based' }
      let(:access_location) { 'invalid-location' }

      it 'is not valid and adds an access error' do
        expect(dro).not_to be_valid
        expect(dro.errors[:access]).to include('is not valid')
      end
    end
  end

  describe 'embargo attributes' do
    context 'when the cocina object has an embargo' do
      let(:embargo_release_date) { DateTime.parse('2040-01-01') }
      let(:embargo_view) { 'world' }
      let(:embargo_download) { 'none' }
      let(:cocina_object) do
        build(:dro_with_metadata).new(
          access: { view: 'world', download: 'world',
                    embargo: { releaseDate: embargo_release_date, view: embargo_view, download: embargo_download } }
        )
      end

      it 'populates embargo attributes from the cocina object' do
        expect(dro.embargo_release_date).to eq embargo_release_date
        expect(dro.embargo_view).to eq embargo_view
        expect(dro.embargo_download).to eq embargo_download
        expect(dro.embargo_location).to be_nil
      end
    end

    context 'when the cocina object has no embargo' do
      it 'returns nil for all embargo attributes' do
        expect(dro.embargo_release_date).to be_nil
        expect(dro.embargo_view).to be_nil
        expect(dro.embargo_download).to be_nil
        expect(dro.embargo_location).to be_nil
      end
    end
  end

  describe 'validate embargo access' do
    let(:embargo_release_date) { DateTime.parse('2040-01-01') }
    let(:embargo_view) { 'world' }
    let(:embargo_download) { 'none' }
    let(:embargo_location) { nil }

    before do
      dro.embargo_release_date = embargo_release_date
      dro.embargo_view = embargo_view
      dro.embargo_download = embargo_download
      dro.embargo_location = embargo_location
    end

    context 'when embargo access is dark' do
      let(:embargo_view) { 'dark' }

      it 'is valid' do
        expect(dro).to be_valid
      end
    end

    context 'when embargo access is citation-only' do
      let(:embargo_view) { 'citation-only' }

      it 'is valid' do
        expect(dro).to be_valid
      end
    end

    context 'when embargo view is location-based and download is none' do
      let(:embargo_view) { 'location-based' }
      let(:embargo_location) { Constants::ACCESS_LOCATIONS.first }

      it 'is valid' do
        expect(dro).to be_valid
      end
    end

    context 'when embargo view is location-based and download is location-based' do
      let(:embargo_view) { 'location-based' }
      let(:embargo_download) { 'location-based' }
      let(:embargo_location) { Constants::ACCESS_LOCATIONS.first }

      it 'is valid' do
        expect(dro).to be_valid
      end
    end

    context 'when embargo download is location-based with stanford view' do
      let(:embargo_view) { 'stanford' }
      let(:embargo_download) { 'location-based' }
      let(:embargo_location) { Constants::ACCESS_LOCATIONS.first }

      it 'is valid' do
        expect(dro).to be_valid
      end
    end

    context 'when embargo download is location-based with world view' do
      let(:embargo_download) { 'location-based' }
      let(:embargo_location) { Constants::ACCESS_LOCATIONS.first }

      it 'is valid' do
        expect(dro).to be_valid
      end
    end

    context 'when embargo access is stanford' do
      let(:embargo_view) { 'stanford' }
      let(:embargo_download) { 'stanford' }

      it 'is valid' do
        expect(dro).to be_valid
      end
    end

    context 'when embargo access is world and download is stanford' do
      let(:embargo_download) { 'stanford' }

      it 'is valid' do
        expect(dro).to be_valid
      end
    end

    context 'when embargo access is world and download is world' do
      let(:embargo_download) { 'world' }

      it 'is valid' do
        expect(dro).to be_valid
      end
    end

    context 'when embargo access combination is invalid' do
      let(:embargo_view) { 'stanford' }
      let(:embargo_download) { 'none' }

      it 'is not valid and adds an embargo_access error' do
        expect(dro).not_to be_valid
        expect(dro.errors[:embargo_access]).to include('is not valid')
      end
    end

    context 'when embargo location is required but missing' do
      let(:embargo_view) { 'location-based' }

      it 'is not valid and adds an embargo_access error' do
        expect(dro).not_to be_valid
        expect(dro.errors[:embargo_access]).to include('is not valid')
      end
    end

    context 'when embargo location is invalid' do
      let(:embargo_view) { 'location-based' }
      let(:embargo_location) { 'invalid-location' }

      it 'is not valid and adds an embargo_access error' do
        expect(dro).not_to be_valid
        expect(dro.errors[:embargo_access]).to include('is not valid')
      end
    end

    context 'when embargo_release_date is absent' do
      let(:embargo_release_date) { nil }
      let(:embargo_view) { 'stanford' }
      let(:embargo_download) { 'none' }

      it 'skips embargo validation' do
        expect(dro).to be_valid
      end
    end
  end

  describe 'content_type' do
    context 'when initialized from a cocina object' do
      let(:cocina_object) { build(:dro_with_metadata, type: Cocina::Models::ObjectType.book) }

      it 'maps content_type from the cocina object type' do
        expect(dro.content_type).to eq(Cocina::Models::ObjectType.book)
      end
    end

    context 'when content_type is blank' do
      before { dro.content_type = nil }

      it 'is not valid' do
        expect(dro).not_to be_valid
        expect(dro.errors[:content_type]).to include("can't be blank")
      end
    end

    context 'when content_type is not in DRO::TYPES' do
      before { dro.content_type = 'https://cocina.sul.stanford.edu/models/invalid' }

      it 'is not valid' do
        expect(dro).not_to be_valid
        expect(dro.errors[:content_type]).to be_present
      end
    end

    context 'when content_type is a valid DRO type' do
      before { dro.content_type = Cocina::Models::ObjectType.image }

      it 'is valid' do
        expect(dro).to be_valid
      end
    end
  end

  describe 'viewing_direction' do
    let(:cocina_object) do
      build(:dro_with_metadata, type: Cocina::Models::ObjectType.book).new(
        structural: { hasMemberOrders: [{ viewingDirection: 'left-to-right' }] }
      )
    end

    it 'maps viewing_direction from structural.hasMemberOrders' do
      expect(dro.viewing_direction).to eq('left-to-right')
    end

    context 'when hasMemberOrders is empty' do
      let(:cocina_object) { build(:dro_with_metadata, type: Cocina::Models::ObjectType.book) }

      it 'maps viewing_direction as nil' do
        expect(dro.viewing_direction).to be_nil
      end
    end

    context 'when viewing_direction is invalid' do
      before { dro.viewing_direction = 'top-to-bottom' }

      it 'is not valid' do
        expect(dro).not_to be_valid
        expect(dro.errors[:viewing_direction]).to be_present
      end
    end

    context 'when viewing_direction is valid and content_type is book' do
      before { dro.viewing_direction = 'right-to-left' }

      it 'is valid' do
        expect(dro).to be_valid
      end
    end

    context 'when viewing_direction is present but content_type is not book or image' do
      let(:cocina_object) { build(:dro_with_metadata, type: Cocina::Models::ObjectType.map) }

      before { dro.viewing_direction = 'left-to-right' }

      it 'is not valid' do
        expect(dro).not_to be_valid
        expect(dro.errors[:viewing_direction]).to include('is only valid for book and image content types')
      end
    end

    context 'when viewing_direction is blank and content_type is not book or image' do
      let(:cocina_object) { build(:dro_with_metadata, type: Cocina::Models::ObjectType.map) }

      it 'is valid' do
        expect(dro).to be_valid
      end
    end
  end

  describe 'validate catalog links' do
    context 'when a folio catalog link has an invalid catalog_record_id' do
      before do
        dro.folio_catalog_links_attributes = [{ catalog_record_id: '11403803' }]
      end

      it 'is not valid' do
        expect(dro).not_to be_valid
        expect(dro.errors[:'folio_catalog_links[0].catalog_record_id']).to be_present
      end
    end

    context 'when sort_key is present without part_label' do
      before do
        dro.catalog_link_sort_key = 'vol. 1'
      end

      it 'is not valid' do
        expect(dro).not_to be_valid
        expect(dro.errors[:catalog_link_sort_key]).to be_present
      end
    end

    context 'when sort_key and part_label are both present' do
      before do
        dro.catalog_link_part_label = 'vol. 1'
        dro.catalog_link_sort_key = 'vol. 1'
      end

      it 'is valid' do
        expect(dro).to be_valid
      end
    end
  end

  # ActiveModel::Lint::Tests expects this method name
  def model
    dro
  end

  # Run all lint tests as RSpec examples
  ActiveModel::Lint::Tests.instance_methods.grep(/^test/).each do |method_name|
    it method_name.to_s do # rubocop:disable RSpec/NoExpectationExample
      send(method_name)
    end
  end
end
