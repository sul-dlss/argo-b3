# frozen_string_literal: true

require 'rails_helper'

RSpec.describe AdministrativeTagsForm do
  let(:druid) { 'druid:bc123df4567' }

  describe '.from_tags' do
    it 'splits the tags into other, project, and ticket tags' do
      form = described_class.from_tags(['Registered By : jdoe', 'Project : Maps : 2024', 'Ticket : DIGREQ-1'])

      expect(form.other_tags.map(&:tag)).to eq(['Registered By : jdoe'])
      expect(form.project_tags.map(&:tag)).to eq(['Maps : 2024'])
      expect(form.ticket_tags.map(&:tag)).to eq(['DIGREQ-1'])
    end
  end

  describe '#tags_changed?' do
    subject(:form) do
      described_class.new(other_tags_attributes: [{ tag: 'Registered By : jdoe' }],
                          project_tags_attributes: [{ tag: 'Maps' }],
                          ticket_tags_attributes: [{ tag: '' }])
    end

    before { form.valid? }

    it 'is true when the tags differ from the current tags' do
      expect(form.tags_changed?(['Registered By : jdoe'])).to be true
    end

    it 'is false when the tags match the current tags' do
      expect(form.tags_changed?(['Registered By : jdoe', 'Project : Maps'])).to be false
    end

    it 'is false when the current tags are in a different order' do
      expect(form.tags_changed?(['Project : Maps', 'Registered By : jdoe'])).to be false
    end
  end

  describe '#save!' do
    before { allow(Sdr::AdministrativeTags).to receive(:replace) }

    it 'replaces the tags' do
      form = described_class.new(project_tags_attributes: [{ tag: 'Maps' }])
      form.valid?
      form.save!(druid:)

      expect(Sdr::AdministrativeTags).to have_received(:replace).with(druid:, tags: ['Project : Maps'])
    end

    it 'replaces the tags with an empty list when all are removed' do
      form = described_class.new
      form.valid?
      form.save!(druid:)

      expect(Sdr::AdministrativeTags).to have_received(:replace).with(druid:, tags: [])
    end
  end

  describe 'validation' do
    it 'is invalid when an other tag lacks a colon-delimited term' do
      form = described_class.new(other_tags_attributes: [{ tag: 'not a tag' }])

      expect(form).not_to be_valid
    end
  end
end
