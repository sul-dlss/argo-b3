# frozen_string_literal: true

require 'rails_helper'

RSpec.describe BulkActions do
  describe '.all' do
    subject(:configs) { described_class.all }

    it 'returns only bulk action configs' do
      expect(configs).to all(be_a(BulkActions::Config))
    end

    it 'includes the bulk action types' do
      expect(configs.map(&:action_type)).to include('ADD_WORKFLOW', 'REDEPOSIT', 'REGISTER_CSV')
    end
  end

  describe '.in_section' do
    it 'returns the configs of the section in definition order' do
      labels = described_class.in_section(:perform_actions).map(&:label)

      expect(labels).to eq(['Manage release', 'Republish', 'Reindex'])
    end
  end

  describe '.section_label' do
    it 'returns the label of the section' do
      expect(described_class.section_label(:rights_and_administrative_metadata))
        .to eq('Manage rights and administrative metadata')
    end
  end

  describe '.available_sections' do
    context 'when the user passes every rule' do
      subject(:sections) { described_class.available_sections { true } }

      it 'returns every section in display order' do
        expect(sections.keys).to eq(%i[perform_actions register_and_deposit tags_and_reporting modify_objects
                                       structural_metadata rights_and_administrative_metadata
                                       descriptive_metadata permissions])
        expect(sections[:perform_actions].map(&:label)).to eq(['Manage release', 'Republish', 'Reindex'])
      end
    end

    context 'when the user passes no rule' do
      subject(:sections) { described_class.available_sections { false } }

      it 'omits configs with a rule and sections left empty' do
        expect(sections.keys).not_to include(:permissions)
        expect(sections[:perform_actions].map(&:label)).to eq(['Manage release', 'Republish', 'Reindex'])
      end
    end

    it 'yields the rule of each config that has one' do
      rules = []
      described_class.available_sections { |rule| rules << rule }

      expect(rules).to eq(%i[manage_permissions? manage_permissions?])
    end
  end

  describe BulkActions::Config do
    describe '#cancellable?' do
      it 'returns true by default' do
        expect(described_class.new.cancellable?).to be true
      end

      it 'returns false when cancellable is false' do
        expect(described_class.new(cancellable: false).cancellable?).to be false
      end
    end
  end
end
