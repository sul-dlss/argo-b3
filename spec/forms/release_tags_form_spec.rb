# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ReleaseTagsForm do
  subject(:release_tags) { described_class.new(**attributes) }

  let(:attributes) { {} }

  describe '#create!' do
    let(:druid) { 'druid:bc123df4567' }
    let(:user_name) { 'jcoyne' }

    before do
      allow(Sdr::Repository).to receive(:create_release_tag)
    end

    context 'when all destinations follow collection settings' do
      let(:attributes) do
        { searchworks_target: 'release_to_collection', earthworks_target: 'release_to_collection',
          purl_sitemap_target: 'release_to_collection' }
      end

      it 'does not create release tags' do
        release_tags.create!(druid:, user_name:)

        expect(Sdr::Repository).not_to have_received(:create_release_tag)
      end
    end

    context 'when destinations have different release choices' do
      let(:attributes) do
        { searchworks_target: 'release_to_targets', earthworks_target: 'no_release',
          purl_sitemap_target: 'release_to_collection' }
      end

      it 'releases and suppresses the chosen destinations without overriding collection settings for the others' do
        release_tags.create!(druid:, user_name:)

        expect(Sdr::Repository).to have_received(:create_release_tag).exactly(2).times
        expect(Sdr::Repository).to have_received(:create_release_tag)
          .with(druid:, user_name:, release_target: 'Searchworks', release: true)
        expect(Sdr::Repository).to have_received(:create_release_tag)
          .with(druid:, user_name:, release_target: 'Earthworks', release: false)
      end
    end

    context 'when all destinations are released' do
      let(:attributes) do
        { searchworks_target: 'release_to_targets', earthworks_target: 'release_to_targets',
          purl_sitemap_target: 'release_to_targets' }
      end

      it 'creates a release tag for each destination' do
        release_tags.create!(druid:, user_name:)

        expect(Sdr::Repository).to have_received(:create_release_tag).exactly(3).times
        expect(Sdr::Repository).to have_received(:create_release_tag)
          .with(druid:, user_name:, release_target: 'Searchworks', release: true)
        expect(Sdr::Repository).to have_received(:create_release_tag)
          .with(druid:, user_name:, release_target: 'Earthworks', release: true)
        expect(Sdr::Repository).to have_received(:create_release_tag)
          .with(druid:, user_name:, release_target: 'PURL sitemap', release: true)
      end
    end

    context 'when no destination is released' do
      let(:attributes) do
        { searchworks_target: 'no_release', earthworks_target: 'no_release', purl_sitemap_target: 'no_release' }
      end

      it 'creates a suppression tag for each destination' do
        release_tags.create!(druid:, user_name:)

        expect(Sdr::Repository).to have_received(:create_release_tag).exactly(3).times
        expect(Sdr::Repository).to have_received(:create_release_tag)
          .with(druid:, user_name:, release_target: 'Searchworks', release: false)
        expect(Sdr::Repository).to have_received(:create_release_tag)
          .with(druid:, user_name:, release_target: 'Earthworks', release: false)
        expect(Sdr::Repository).to have_received(:create_release_tag)
          .with(druid:, user_name:, release_target: 'PURL sitemap', release: false)
      end
    end
  end
end
