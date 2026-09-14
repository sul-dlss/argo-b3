# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ProjectTagForm do
  subject(:project_tag_form) { described_class.new(tag:) }

  describe 'tag' do
    context 'when blank' do
      let(:tag) { '' }

      it 'is normalized to nil' do
        expect(project_tag_form.tag).to be_nil
      end
    end

    context 'when whitespace only' do
      let(:tag) { '   ' }

      it 'is normalized to nil' do
        expect(project_tag_form.tag).to be_nil
      end
    end

    context 'when surrounded by whitespace' do
      let(:tag) { '  Argo  ' }

      it 'is normalized by stripping whitespace' do
        expect(project_tag_form.tag).to eq('Argo')
      end
    end

    context 'when prefixed with "Project : "' do
      let(:tag) { 'Project : Argo' }

      it 'is normalized by removing the prefix' do
        expect(project_tag_form.tag).to eq('Argo')
      end
    end

    context 'when prefixed with "Project : " and surrounded by whitespace' do
      let(:tag) { '  Project : Argo  ' }

      it 'is normalized by removing the prefix and stripping whitespace' do
        expect(project_tag_form.tag).to eq('Argo')
      end
    end

    context 'when the prefix appears but not at the beginning' do
      let(:tag) { 'Argo : Project : Foo' }

      it 'is not removed' do
        expect(project_tag_form.tag).to eq('Argo : Project : Foo')
      end
    end
  end
end
