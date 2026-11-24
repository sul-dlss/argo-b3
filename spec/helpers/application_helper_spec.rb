# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ApplicationHelper do
  describe '#facet_plural_label' do
    it 'pluralizes a configured label' do
      expect(helper.facet_plural_label(:mimetypes)).to eq('MIME types')
    end

    it 'pluralizes the default label' do
      expect(helper.facet_plural_label(:topics)).to eq('Topics')
    end

    it 'leaves an already plural label as it is' do
      expect(helper.facet_plural_label(:access_rights)).to eq('Access rights')
    end

    it 'uses a configured plural' do
      expect(helper.facet_plural_label(:wps_workflows)).to eq('Workflows')
    end
  end

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
