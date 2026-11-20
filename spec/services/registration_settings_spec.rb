# frozen_string_literal: true

require 'rails_helper'

RSpec.describe RegistrationSettings do
  subject(:registration_settings) { described_class.new(cocina_object:) }

  let(:cocina_object) do
    build(:dro_with_metadata, id: 'druid:bc123df4567', type: Cocina::Models::ObjectType.book,
                              admin_policy_id: 'druid:hv992ry2431', collection_ids: ['druid:xz987wv6543'],
                              source_id: 'sul:abc123', barcode: '36105010101010')
      .new(access: { view: 'stanford', download: 'stanford',
                     useAndReproductionStatement: 'Property rights reside with the repository.',
                     copyright: 'Copyright © Stanford University.',
                     license: 'https://creativecommons.org/licenses/by/4.0/legalcode',
                     embargo: { releaseDate: '2040-06-15T00:00:00Z', view: 'world', download: 'world' } })
  end

  let(:release_tags) do
    [Dor::Services::Client::ReleaseTag.new(to: 'Searchworks', release: true, what: 'self', who: 'jdoe',
                                           date: '2026-01-01T00:00:00Z'),
     Dor::Services::Client::ReleaseTag.new(to: 'Searchworks', release: false, what: 'self', who: 'jdoe',
                                           date: '2026-02-01T00:00:00Z')]
  end

  before do
    allow(Sdr::AdministrativeTags).to receive(:list)
      .and_return(['Project : Maps', 'Ticket : DIGREQ-1', 'Registered By : jdoe'])
    allow(Sdr::Repository).to receive(:release_tags).and_return(release_tags)
  end

  describe '#items_registration_form_attributes' do
    it 'copies the settings and tags but not the identifiers or description' do
      expect(registration_settings.items_registration_form_attributes).to eq(
        content_type: 'https://cocina.sul.stanford.edu/models/book',
        apo_druid: 'druid:hv992ry2431',
        collection_druids: ['druid:xz987wv6543'],
        access_view: 'stanford',
        access_download: 'stanford',
        access_location: nil,
        embargo_release_date: DateTime.parse('2040-06-15T00:00:00Z'),
        embargo_view: 'world',
        embargo_download: 'world',
        embargo_location: nil,
        viewing_direction: nil,
        use_and_reproduction_statement: 'Property rights reside with the repository.',
        copyright: 'Copyright © Stanford University.',
        license: 'https://creativecommons.org/licenses/by/4.0/legalcode',
        other_tags_attributes: [{ tag: 'Registered By : jdoe' }],
        project_tags_attributes: [{ tag: 'Project : Maps' }],
        ticket_tags_attributes: [{ tag: 'Ticket : DIGREQ-1' }]
      )
      expect(Sdr::AdministrativeTags).to have_received(:list).with(druid: 'druid:bc123df4567')
    end
  end

  describe '#new_item_form_attributes' do
    it 'also copies the latest release tag of each of the item’s own release targets' do
      expect(registration_settings.new_item_form_attributes)
        .to include(release_tags_attributes: { searchworks_target: 'no_release' })
      expect(Sdr::Repository).to have_received(:release_tags).with(druid: 'druid:bc123df4567', public: false)
    end
  end
end
