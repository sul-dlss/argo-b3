# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Search::FacetPathResolver do
  # Path helper names are built from strings rather than referenced as constants, so there is no
  # load-time check that they exist. These are a sample rather than every facet: one configuration
  # per combination of declared endpoints, under each view, which covers every branch in the
  # resolver and would catch endpoints added to only one view's routes.
  def self.sampled_facets
    [
      { config: Search::Facets::TAGS, index: true, children: true, search: true },
      { config: Search::Facets::WORKFLOWS, index: true, children: true, search: false },
      { config: Search::Facets::MIMETYPES, index: true, children: false, search: true },
      { config: Search::Facets::ACCESS_RIGHTS, index: false, children: false, search: false }
    ]
  end

  sampled_facets.each do |sample|
    [ResultsSearchForm, WorkflowGridSearchForm].each do |form_class|
      context "with #{sample[:config].form_field} in #{form_class.route_scope}" do
        let(:search_form) { form_class.new }
        let(:facet_config) { sample[:config] }

        it 'resolves a helper for exactly the declared endpoints' do
          expect(
            {
              index: described_class.index_path_helper(facet_config:, search_form:).present?,
              children: described_class.children_path_helper(facet_config:, search_form:).present?,
              search: described_class.search_path_helper(facet_config:, search_form:).present?
            }
          ).to eq(sample.slice(:index, :children, :search))
        end
      end
    end
  end

  def all_facet_configs
    Search::Facets.constants.map { |name| Search::Facets.const_get(name) }.grep(Search::Facets::Config)
  end

  def resolved_helpers(facet_config:, search_form:)
    %i[index_path_helper children_path_helper search_path_helper].filter_map do |resolver|
      described_class.public_send(resolver, facet_config:, search_form:)
    end
  end

  describe 'every facet configuration' do
    # A single example over all of the configurations, rather than one each: this is here to catch a
    # mistake in an individual facet's own configuration -- a typo in facet_resource, or a declared
    # endpoint whose route was never added to the :search_endpoints concern -- which the sampled
    # examples above would miss.
    it 'declares endpoints that exist under every view' do
      paths = all_facet_configs.flat_map do |facet_config|
        [ResultsSearchForm, WorkflowGridSearchForm].flat_map do |form_class|
          resolved_helpers(facet_config:, search_form: form_class.new).map do |helper|
            # Calling the helper raises if the route it was built from does not exist.
            [facet_config.form_field, helper.call]
          end
        end
      end

      expect(paths).to all(satisfy { |_form_field, path| path.start_with?('/search/', '/workflow_grid/') })
    end
  end

  describe 'resolved paths' do
    it 'builds paths under the search results view' do
      helper = described_class.index_path_helper(facet_config: Search::Facets::TAGS,
                                                 search_form: ResultsSearchForm.new(query: 'twain'))

      expect(helper.call(query: 'twain')).to eq('/search/tag_facets?query=twain')
    end

    it 'builds paths under the workflow grid view' do
      helper = described_class.index_path_helper(facet_config: Search::Facets::TAGS,
                                                 search_form: WorkflowGridSearchForm.new(query: 'twain'))

      expect(helper.call(query: 'twain')).to eq('/workflow_grid/tag_facets?query=twain')
    end

    it 'builds children paths for hierarchical facets' do
      helper = described_class.children_path_helper(facet_config: Search::Facets::TAGS,
                                                    search_form: WorkflowGridSearchForm.new)

      expect(helper.call(parent_value: 'Registered By')).to eq(
        '/workflow_grid/tag_facets/children?parent_value=Registered+By'
      )
    end

    it 'builds facet search paths' do
      helper = described_class.search_path_helper(facet_config: Search::Facets::TAGS,
                                                  search_form: WorkflowGridSearchForm.new)

      expect(helper.call(q: 'reg')).to eq('/workflow_grid/tag_facets/search?q=reg')
    end
  end
end
