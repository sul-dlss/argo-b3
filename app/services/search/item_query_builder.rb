# frozen_string_literal: true

module Search
  # Builds the query parts (q, fq) of a Solr request for items
  class ItemQueryBuilder
    include Search::Fields

    FACETS = [
      Search::Facets::ACCESS_RIGHTS,
      Search::Facets::ADMIN_POLICIES,
      Search::Facets::COLLECTIONS,
      Search::Facets::CONTENT_TYPES,
      Search::Facets::DATES,
      Search::Facets::FILE_ROLES,
      Search::Facets::GENRES,
      Search::Facets::EARLIEST_ACCESSIONED_DATE,
      Search::Facets::EMBARGO_RELEASE_DATE,
      Search::Facets::IDENTIFIERS,
      Search::Facets::LANGUAGES,
      Search::Facets::LAST_ACCESSIONED_DATE,
      Search::Facets::LAST_OPENED_DATE,
      Search::Facets::LAST_PUBLISHED_DATE,
      Search::Facets::LICENSES,
      Search::Facets::METADATA_SOURCES,
      Search::Facets::MIMETYPES,
      Search::Facets::MODS_RESOURCE_TYPES,
      Search::Facets::OBJECT_TYPES,
      Search::Facets::PROCESSING_STATUSES,
      Search::Facets::PROJECTS,
      Search::Facets::REGIONS,
      Search::Facets::REGISTERED_DATE,
      Search::Facets::TAGS,
      Search::Facets::TICKETS,
      Search::Facets::TOPICS,
      Search::Facets::RELEASED_TO_EARTHWORKS,
      Search::Facets::RELEASED_TO_PURL_SITEMAP,
      Search::Facets::RELEASED_TO_SEARCHWORKS,
      Search::Facets::SW_RESOURCE_TYPES,
      Search::Facets::VERSIONS,
      Search::Facets::WORKFLOWS
    ].freeze

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
      [].tap do |queries|
        FACETS.each do |facet_config|
          if facet_config.dynamic_facet.present?
            queries << dynamic_facet_filter_query(facet_config:)
          else
            queries << facet_filter_query(facet_config:)
            queries << facet_filter_query(facet_config:, exclude: true) if facet_config.exclude_form_field.present?
          end
        end
        queries << "-#{APO_DRUID}:\"#{Settings.google_books_apo}\"" unless search_form.include_google_books
      end.compact
    end

    # Construct a facet filter query for the given form field and Solr field for value facets.
    # @param facet_config [Search::Facets::Config]
    # @param exclude [Boolean] whether to negate the query
    def facet_filter_query(facet_config:, exclude: false)
      form_field = exclude ? facet_config.exclude_form_field : facet_config.form_field
      return if search_form.send(form_field).blank?

      values = search_form.send(form_field).map { |value| "\"#{value}\"" }.join(' OR ')
      query = "#{'-' if exclude}#{facet_config.field}:(#{values})"
      # Tagging is used to exclude the filter from the facet counts.
      # This is useful for checkbox facets (in all values for the facet should be returned).
      # See https://solr.apache.org/guide/8_11/faceting.html#tagging-and-excluding-filters
      facet_config.exclude ? "{!tag=#{facet_config.field}}#{query}" : query
    end

    # Construct a facet filter query for the given dynamic facet configuration.
    # @param facet_config [Search::Facets::Config]
    def dynamic_facet_filter_query(facet_config:)
      query_parts = search_form.send(facet_config.form_field).map do |value|
        query = facet_config.dynamic_facet[value.to_sym]
        "(#{query})"
      end
      date_range_query_part = date_range_query_part(facet_config:)
      query_parts << date_range_query_part if date_range_query_part.present?
      return if query_parts.empty?

      query_parts.compact.join(' OR ')
    end

    def date_range_query_part(facet_config:)
      date_from = search_form.send(facet_config.date_from_form_field) if facet_config.date_from_form_field
      date_to = search_form.send(facet_config.date_to_form_field) if facet_config.date_to_form_field
      return if date_from.blank? && date_to.blank?

      from_part = date_from.present? ? date_from.strftime('%Y-%m-%dT00:00:00Z') : '*'
      to_part = date_to.present? ? date_to.strftime('%Y-%m-%dT23:59:59Z') : '*'
      "#{facet_config.field}:[#{from_part} TO #{to_part}]"
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
