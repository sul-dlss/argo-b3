# frozen_string_literal: true

module Search
  # Builds the query parts (q, fq) of a Solr request for items
  class ItemQueryBuilder
    include Search::Fields

    def self.call(...)
      new(...).call
    end

    # @param search_form [Search::ItemForm]
    def initialize(search_form:)
      @search_form = search_form
    end

    # @return [Hash] parts of Solr request
    def call
      # Note that this will override values specified in solrconfig.xml
      {
        q: search_form.query,
        fq: filter_queries,
        debugQuery: search_form.debug,
        qf: query_fields,
        defType: 'dismax',
        'q.alt': '*:*'
      }.compact_blank
    end

    private

    attr_reader :search_form

    def filter_queries # rubocop:disable Metrics/AbcSize
      queries = []
      queries << facet_filter_query(form_field: :object_types, solr_field: OBJECT_TYPE, tag: true)
      queries << facet_filter_query(form_field: :projects, solr_field: PROJECT_TAGS)
      queries << facet_filter_query(form_field: :tags, solr_field: OTHER_TAGS)
      queries << facet_filter_query(form_field: :wps_workflows, solr_field: WPS_WORKFLOWS)
      queries << facet_filter_query(form_field: :access_rights, solr_field: ACCESS_RIGHTS)
      queries << facet_filter_query(form_field: :access_rights_exclude, solr_field: ACCESS_RIGHTS, exclude: true)
      queries << facet_filter_query(form_field: :mimetypes, solr_field: MIMETYPES)
      queries << dynamic_facet_filter_query(facet_config: Search::Facets::RELEASED_TO_EARTHWORKS)
      queries << "-#{APO_ID}:\"#{Settings.google_books_apo}\"" unless search_form.include_google_books
      queries.compact
    end

    # Construct a facet filter query for the given form field and Solr field for value facets.
    # @param form_field [Symbol] the attribute on the search form
    # @param solr_field [String] the Solr field to filter on
    # @param tag [Boolean] whether to tag the filter (for exclusion from facet counts)
    def facet_filter_query(form_field:, solr_field:, tag: false, exclude: false)
      return if search_form.send(form_field).blank?

      values = search_form.send(form_field).map { |value| "\"#{value}\"" }.join(' OR ')
      query = "#{'-' if exclude}#{solr_field}:(#{values})"
      # Tagging is used to exclude the filter from the facet counts.
      # This is useful for checkbox facets (in all values for the facet should be returned).
      # See https://solr.apache.org/guide/8_11/faceting.html#tagging-and-excluding-filters
      tag ? "{!tag=#{solr_field}}#{query}" : query
    end

    # Construct a facet filter query for the given dynamic facet configuration.
    # @param facet_config [Search::Facets::Config]
    def dynamic_facet_filter_query(facet_config:)
      return if search_form.send(facet_config.form_field).blank?

      query_parts = search_form.send(facet_config.form_field).map do |value|
        query = facet_config.dynamic_facet[value.to_sym]
        "(#{query})"
      end
      query_parts.join(' OR ')
    end

    def query_fields # rubocop:disable Metrics/MethodLength
      %W[
        main_title_text_anchored_im^100
        main_title_text_unstemmed_im^50
        main_title_tenim^10
        full_title_unstemmed_im^10
        full_title_tenim^5
        additional_titles_unstemmed_im^5
        additional_titles_tenim^3
        author_text_nostem_im^3
        contributor_text_nostem_im
        subject_topic_tesim^2
        tag_text_unstemmed_im
        originInfo_place_placeTerm_tesim
        originInfo_publisher_tesim
        content_type_ssimdv
        sw_resource_type_ssimdv
        object_type_ssim
        descriptive_text_nostem_i
        descriptive_tiv
        descriptive_teiv
        collection_title_tesim
        #{ID}
        druid_bare_ssi
        druid_prefixed_ssi
        obj_label_tesim
        identifier_ssim
        identifier_tesim
        barcode_id_ssimdv
        folio_instance_hrid_ssim
        source_id_text_nostem_i^3
        source_id_ssi
        previous_ils_ids_ssim
        doi_ssimdv
        contributor_orcids_ssimdv
      ].join(' ')
    end
  end
end
