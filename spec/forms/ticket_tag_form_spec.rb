# frozen_string_literal: true

require 'rails_helper'

RSpec.describe TicketTagForm do
  subject(:ticket_tag_form) { described_class.new(tag:) }

  describe 'tag' do
    context 'when blank' do
      let(:tag) { '' }

      it 'is normalized to nil' do
        expect(ticket_tag_form.tag).to be_nil
      end
    end

    context 'when whitespace only' do
      let(:tag) { '   ' }

      it 'is normalized to nil' do
        expect(ticket_tag_form.tag).to be_nil
      end
    end

    context 'when surrounded by whitespace' do
      let(:tag) { '  ABC-123  ' }

      it 'is normalized by stripping whitespace' do
        expect(ticket_tag_form.tag).to eq('ABC-123')
      end
    end

    context 'when prefixed with "Ticket : "' do
      let(:tag) { 'Ticket : ABC-123' }

      it 'is normalized by removing the prefix' do
        expect(ticket_tag_form.tag).to eq('ABC-123')
      end
    end

    context 'when prefixed with "Ticket : " and surrounded by whitespace' do
      let(:tag) { '  Ticket : ABC-123  ' }

      it 'is normalized by removing the prefix and stripping whitespace' do
        expect(ticket_tag_form.tag).to eq('ABC-123')
      end
    end

    context 'when the prefix appears but not at the beginning' do
      let(:tag) { 'ABC-123 : Ticket : Foo' }

      it 'is not removed' do
        expect(ticket_tag_form.tag).to eq('ABC-123 : Ticket : Foo')
      end
    end
  end
end
