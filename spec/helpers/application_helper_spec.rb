# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ApplicationHelper do
  describe '#document_title' do
    it 'is the product name when the page sets no title' do
      expect(helper.document_title).to eq('Argo B3')
    end

    it 'appends the product name to the page title' do
      helper.page_title('Manage files', name: 'Maps & charts')

      expect(helper.document_title).to eq('Manage files – Maps &amp; charts | Argo B3')
    end

    it 'omits a blank name' do
      helper.page_title('Edit item', name: '')

      expect(helper.document_title).to eq('Edit item | Argo B3')
    end
  end
end
