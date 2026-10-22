# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CollectionReleaseTagsForm do
  subject(:release_tags) { described_class.new(**attributes) }

  let(:attributes) { {} }

  describe '#create!' do
    let(:druid) { 'druid:bc123df4567' }
    let(:user_name) { 'jcoyne' }

    before do
      allow(Sdr::Repository).to receive(:create_release_tag)
    end

    context 'when no destinations are released' do
      it 'does not create release tags' do
        release_tags.create!(druid:, user_name:)

        expect(Sdr::Repository).not_to have_received(:create_release_tag)
      end
    end

    context 'when destinations release the collection or the collection and its member items' do
      let(:attributes) do
        { searchworks_target: 'collection', earthworks_target: 'self', purl_sitemap_target: 'no_release' }
      end

      it 'creates a release tag for what is released to each released destination' do
        release_tags.create!(druid:, user_name:)

        expect(Sdr::Repository).to have_received(:create_release_tag).twice
        expect(Sdr::Repository).to have_received(:create_release_tag)
          .with(druid:, user_name:, release_target: 'Searchworks', release: true, release_what: 'collection')
        expect(Sdr::Repository).to have_received(:create_release_tag)
          .with(druid:, user_name:, release_target: 'Earthworks', release: true, release_what: 'self')
      end
    end
  end
end
