# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ItemReleaseTagsForm do
  let(:druid) { 'druid:bc123df4567' }
  let(:user_name) { 'jcoyne' }
  let(:release_tags) do
    [
      release_tag(to: 'Searchworks', release: false, date: '2025-01-01T00:00:00Z'),
      release_tag(to: 'Searchworks', release: true, date: '2026-01-01T00:00:00Z'),
      release_tag(to: 'PURL sitemap', release: false, date: '2025-06-01T00:00:00Z')
    ]
  end

  def release_tag(to:, release:, date:)
    Dor::Services::Client::ReleaseTag.new(to:, release:, date:, what: 'self', who: 'jcoyne')
  end

  before { allow(Sdr::Repository).to receive(:create_release_tag) }

  describe '.from_release_tags' do
    it 'selects the latest tag for tagged targets and follows the collection otherwise' do
      form = described_class.from_release_tags(release_tags)

      expect(form.searchworks_target).to eq described_class::RELEASE
      expect(form.earthworks_target).to eq described_class::FOLLOW_COLLECTION
      expect(form.purl_sitemap_target).to eq described_class::NO_RELEASE
    end
  end

  describe '#save!' do
    subject(:form) { described_class.new(**attributes) }

    context 'when every target follows the collection' do
      let(:attributes) { {} }

      it 'creates no release tags' do
        expect(form.save!(druid:, user_name:, release_tags:)).to eq []
        expect(Sdr::Repository).not_to have_received(:create_release_tag)
      end
    end

    context 'when choices differ from the latest tags or a target is untagged' do
      let(:attributes) do
        { searchworks_target: 'no_release', earthworks_target: 'release_to_targets', purl_sitemap_target: 'no_release' }
      end

      it 'creates a release tag for each target whose choice changed' do
        expect(form.save!(druid:, user_name:, release_tags:)).to eq %w[Searchworks Earthworks]
        expect(Sdr::Repository).to have_received(:create_release_tag).twice
        expect(Sdr::Repository).to have_received(:create_release_tag)
          .with(druid:, user_name:, release_target: 'Searchworks', release: false)
        expect(Sdr::Repository).to have_received(:create_release_tag)
          .with(druid:, user_name:, release_target: 'Earthworks', release: true)
      end
    end

    context 'when following the collection is submitted for a tagged target' do
      let(:attributes) { { searchworks_target: 'release_to_collection' } }

      it 'creates no release tag' do
        expect(form.save!(druid:, user_name:, release_tags:)).to eq []
        expect(Sdr::Repository).not_to have_received(:create_release_tag)
      end
    end
  end
end
