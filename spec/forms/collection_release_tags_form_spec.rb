# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CollectionReleaseTagsForm do
  let(:druid) { 'druid:bc123df4567' }
  let(:user_name) { 'jcoyne' }
  let(:now) { Time.utc(2026, 3, 4, 5, 6, 7) }

  def release_tag(to:, release:, what:, date:)
    Dor::Services::Client::ReleaseTag.new(to:, release:, what:, date:, who: 'someone')
  end

  describe '.from_release_tags' do
    subject(:form) { described_class.from_release_tags(release_tags) }

    let(:release_tags) do
      [
        release_tag(to: 'Searchworks', release: true, what: 'collection', date: '2026-01-01T00:00:00Z'),
        release_tag(to: 'Searchworks', release: true, what: 'self', date: '2026-02-01T00:00:00Z'),
        release_tag(to: 'Earthworks', release: true, what: 'collection', date: '2026-02-01T00:00:00Z'),
        release_tag(to: 'Earthworks', release: false, what: 'self', date: '2026-01-01T00:00:00Z'),
        release_tag(to: 'PURL sitemap', release: true, what: 'collection', date: '2026-01-01T00:00:00Z'),
        release_tag(to: 'PURL sitemap', release: false, what: 'collection', date: '2026-02-01T00:00:00Z')
      ]
    end

    it 'releases each target as its latest tag does' do
      expect(form).to have_attributes(searchworks_release: true, searchworks_what: 'self',
                                      earthworks_release: true, earthworks_what: 'collection',
                                      purl_sitemap_release: false)
    end
  end

  describe '#create!' do
    subject(:form) { described_class.new(**attributes) }

    before { allow(Sdr::Repository).to receive(:create_release_tag) }

    context 'when no targets are released' do
      let(:attributes) { {} }

      it 'does not create release tags' do
        form.create!(druid:, user_name:)

        expect(Sdr::Repository).not_to have_received(:create_release_tag)
      end
    end

    context 'when targets release the collection or the collection and its member items' do
      let(:attributes) do
        { searchworks_release: true, searchworks_what: 'collection', earthworks_release: true, earthworks_what: 'self' }
      end

      it 'creates a release tag for what is released to each released target' do
        travel_to(now) { form.create!(druid:, user_name:) }

        expect(Sdr::Repository).to have_received(:create_release_tag).twice
        expect(Sdr::Repository).to have_received(:create_release_tag)
          .with(druid:, user_name:, release_target: 'Searchworks', release: true, release_what: 'collection', date: now)
        expect(Sdr::Repository).to have_received(:create_release_tag)
          .with(druid:, user_name:, release_target: 'Earthworks', release: true, release_what: 'self', date: now)
      end
    end
  end

  describe '#save!' do
    subject(:form) { described_class.new(**attributes) }

    let(:saved_targets) { travel_to(now) { form.save!(druid:, user_name:, release_tags:) } }

    before { allow(Sdr::Repository).to receive(:create_release_tag) }

    context 'when a target is unchanged' do
      let(:release_tags) do
        [release_tag(to: 'Searchworks', release: true, what: 'self', date: '2026-01-01T00:00:00Z'),
         release_tag(to: 'Earthworks', release: false, what: 'self', date: '2026-01-01T00:00:00Z')]
      end
      let(:attributes) { { searchworks_release: true, searchworks_what: 'self' } }

      it 'creates no release tags' do
        expect(saved_targets).to eq([])
        expect(Sdr::Repository).not_to have_received(:create_release_tag)
      end
    end

    context 'when a released target is unchecked' do
      let(:release_tags) do
        [release_tag(to: 'Searchworks', release: true, what: 'self', date: '2026-01-01T00:00:00Z')]
      end
      let(:attributes) { { searchworks_release: false } }

      it 'withdraws the collection and its member items' do
        expect(saved_targets).to eq(['Searchworks'])
        expect(Sdr::Repository).to have_received(:create_release_tag).once
        expect(Sdr::Repository).to have_received(:create_release_tag)
          .with(druid:, user_name:, release_target: 'Searchworks', release: false, release_what: 'collection',
                date: now)
      end
    end

    context 'when changed from the collection to the collection and its member items' do
      let(:release_tags) do
        [release_tag(to: 'Earthworks', release: true, what: 'self', date: '2026-01-01T00:00:00Z')]
      end
      let(:attributes) { { earthworks_release: true, earthworks_what: 'collection' } }

      it 'releases the collection and its member items' do
        expect(saved_targets).to eq(['Earthworks'])
        expect(Sdr::Repository).to have_received(:create_release_tag).once
        expect(Sdr::Repository).to have_received(:create_release_tag)
          .with(druid:, user_name:, release_target: 'Earthworks', release: true, release_what: 'collection', date: now)
      end
    end

    context 'when changed from the collection and its member items to the collection' do
      let(:release_tags) do
        [release_tag(to: 'Earthworks', release: true, what: 'collection', date: '2026-01-01T00:00:00Z')]
      end
      let(:attributes) { { earthworks_release: true, earthworks_what: 'self' } }

      it 'withdraws the member items and then releases the collection' do
        expect(saved_targets).to eq(['Earthworks'])
        expect(Sdr::Repository).to have_received(:create_release_tag)
          .with(druid:, user_name:, release_target: 'Earthworks', release: false, release_what: 'collection',
                date: now - 1.second).ordered
        expect(Sdr::Repository).to have_received(:create_release_tag)
          .with(druid:, user_name:, release_target: 'Earthworks', release: true, release_what: 'self', date: now)
          .ordered
      end
    end

    context 'when the latest tag is less than a second old' do
      let(:release_tags) do
        [release_tag(to: 'Earthworks', release: true, what: 'collection', date: now.iso8601)]
      end
      let(:attributes) { { earthworks_release: true, earthworks_what: 'self' } }

      it 'dates the new tags after it' do
        saved_targets

        expect(Sdr::Repository).to have_received(:create_release_tag)
          .with(druid:, user_name:, release_target: 'Earthworks', release: false, release_what: 'collection',
                date: now + 1.second).ordered
        expect(Sdr::Repository).to have_received(:create_release_tag)
          .with(druid:, user_name:, release_target: 'Earthworks', release: true, release_what: 'self',
                date: now + 2.seconds).ordered
      end
    end

    context 'when the latest tag is dated later than now' do
      let(:release_tags) do
        [release_tag(to: 'Searchworks', release: true, what: 'self', date: (now + 1.minute).iso8601)]
      end
      let(:attributes) { { searchworks_release: false } }

      it 'dates the new tag after it' do
        saved_targets

        expect(Sdr::Repository).to have_received(:create_release_tag)
          .with(druid:, user_name:, release_target: 'Searchworks', release: false, release_what: 'collection',
                date: now + 1.minute + 1.second)
      end
    end

    context 'when the collection is released while an earlier tag still releases its member items' do
      let(:release_tags) do
        [release_tag(to: 'Earthworks', release: true, what: 'collection', date: '2026-01-01T00:00:00Z'),
         release_tag(to: 'Earthworks', release: false, what: 'self', date: '2026-02-01T00:00:00Z')]
      end
      let(:attributes) { { earthworks_release: true, earthworks_what: 'self' } }

      it 'withdraws the member items too' do
        saved_targets

        expect(Sdr::Repository).to have_received(:create_release_tag).twice
        expect(Sdr::Repository).to have_received(:create_release_tag)
          .with(druid:, user_name:, release_target: 'Earthworks', release: false, release_what: 'collection',
                date: now - 1.second)
      end
    end

    context 'when the collection is released after its member items were withdrawn' do
      let(:release_tags) do
        [release_tag(to: 'Earthworks', release: false, what: 'collection', date: '2026-01-01T00:00:00Z')]
      end
      let(:attributes) { { earthworks_release: true, earthworks_what: 'self' } }

      it 'only releases the collection' do
        saved_targets

        expect(Sdr::Repository).to have_received(:create_release_tag).once
        expect(Sdr::Repository).to have_received(:create_release_tag)
          .with(druid:, user_name:, release_target: 'Earthworks', release: true, release_what: 'self', date: now)
      end
    end
  end
end
