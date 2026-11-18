# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Contents::LabelUpdater do
  let(:content) { create(:content) }

  before do
    labels.each.with_index(1) do |label, position|
      create(:content_file_set, content:, position:, label:)
    end
  end

  def updated_labels
    content.content_file_sets.reload.map(&:label)
  end

  context 'with numbered labels out of order' do
    let(:labels) { ['Page 1', 'Page 3', 'Page 2'] }

    it 'renumbers them in resource order' do
      described_class.call(content:)

      expect(updated_labels).to eq(['Page 1', 'Page 2', 'Page 3'])
    end
  end

  context 'with numbered labels for several names' do
    let(:labels) { ['Video file 2', 'Image 4', 'Video file 1', 'Image 2', 'File 7'] }

    it 'numbers each name separately, as they occur in order' do
      described_class.call(content:)

      expect(updated_labels).to eq(['Video file 1', 'Image 1', 'Video file 2', 'Image 2', 'File 1'])
    end
  end

  context 'with labels that are not numbered' do
    let(:labels) do
      ['Cover', 'Page 3', '', 'Page 3a', 'Video file 1 transcript', 'Image of media (1 of 2)', 'Page 1', '7']
    end

    it 'leaves them unchanged and does not count them' do
      described_class.call(content:)

      expect(updated_labels).to eq(['Cover', 'Page 1', '', 'Page 3a', 'Video file 1 transcript',
                                    'Image of media (1 of 2)', 'Page 2', '7'])
    end
  end
end
