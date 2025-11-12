# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Search::ItemForm do
  describe '#this_attribute_names' do
    it 'returns the attribute names defined in this form' do
      # Only testing some of the attributes so that the test is not brittle.
      expect(described_class.this_attribute_names).to include('projects', 'object_types')
    end

    it 'does not return attribute names defined in superclasses' do
      expect(described_class.this_attribute_names).not_to include('query', 'page')
    end
  end

  describe '#current_filters' do
    it 'returns the current filters as attribute name/value pairs' do
      form = described_class.new(
        object_types: %w[item collection],
        projects: ['Project 1']
      )

      expect(form.current_filters).to contain_exactly(
        %w[object_types item],
        %w[object_types collection],
        ['projects', 'Project 1']
      )
    end
  end
end
