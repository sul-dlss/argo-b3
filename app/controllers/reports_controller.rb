# frozen_string_literal: true

# Controller for reports
class ReportsController < ApplicationController
  before_action :set_report_form, only: %i[download preview]

  # These are the categories of report fields.
  # Report fields are defined in Reports::Fields.
  # These groupings are used to render sections in the report form.
  FREQUENTLY_USED_FIELDS = [
    Reports::Fields::DRUID,
    Reports::Fields::PURL,
    Reports::Fields::TITLE,
    Reports::Fields::SOURCE_ID,
    Reports::Fields::COLLLECTION_TITLE,
    Reports::Fields::PROJECT,
    Reports::Fields::TAGS,
    Reports::Fields::PROCESSING_STATUS,
    Reports::Fields::RELEASED_TO,
    Reports::Fields::OBJECT_TYPE,
    Reports::Fields::CONTENT_TYPE,
    Reports::Fields::APO_TITLE,
    Reports::Fields::ACCESS_RIGHTS
  ].freeze

  CITATION_FIELDS = [
    Reports::Fields::AUTHORS,
    Reports::Fields::PUBLICATION_PLACE,
    Reports::Fields::PUBLISHER,
    Reports::Fields::PUBLICATION_CREATED_DATE
  ].freeze

  HISTORY_FIELDS = [
    Reports::Fields::REGISTERED_DATE,
    Reports::Fields::ACCESSIONED_DATE,
    Reports::Fields::PUBLISHED_DATE,
    Reports::Fields::EMBARGO_RELEASE_DATE,
    Reports::Fields::REGISTERED_BY,
    Reports::Fields::VERSION,
    Reports::Fields::TICKETS,
    Reports::Fields::WORKFLOW_ERRORS
  ].freeze

  IDENTIFIERS_FIELDS = [
    Reports::Fields::CATALOG_RECORD_ID,
    Reports::Fields::BARCODES,
    Reports::Fields::APO_DRUID,
    Reports::Fields::COLLECTION_DRUID,
    Reports::Fields::DISSERTATION_ID,
    Reports::Fields::DOI
  ].freeze

  CONTENT_FIELDS = [
    Reports::Fields::FILE_COUNT,
    Reports::Fields::SHELVED_FILE_COUNT,
    Reports::Fields::RESOURCE_COUNT,
    Reports::Fields::CONSTITUENTS_COUNT,
    Reports::Fields::HUMAN_PRESERVED_SIZE,
    Reports::Fields::PRESERVATION_SIZE
  ].freeze

  def show
    @report_form = ReportForm.new(fields: FREQUENTLY_USED_FIELDS.map(&:field))
    set_from_last_search_cookie
    @report_form.source = 'results' if @search_form.present?
  end

  def download
    add_report_response_headers

    generate_report(stream: response.stream)
  end

  def preview
    @csv = generate_report
  end

  private

  def report_params
    params.expect(report_form: [:source, :druid_list, { fields: [] }])
  end

  def rows
    params[:commit] == 'Preview' ? 5 : 10_000_000
  end

  def add_report_response_headers
    response.headers['Cache-Control'] = 'no-cache'
    response.headers['Content-Type'] = 'text/csv'
    response.headers['Content-Disposition'] = 'attachment; filename="report.csv"'
    response.headers['Last-Modified'] = Time.now.utc.rfc2822 # HTTP requires GMT date/time
  end

  def generate_report(stream: nil)
    if @report_form.source == 'results'
      generate_report_from_last_search(stream:)
    else
      generate_report_from_druids(stream:)
    end
  end

  def generate_report_from_last_search(stream: nil)
    form_params, @total_results = cookies.signed[:last_search]&.values_at('form', 'total_results')
    search_form = SearchForm.new(form_params)

    Searchers::Report.call(search_form:, fields: @report_form.fields, rows:, stream:)
  end

  def generate_report_from_druids(stream: nil)
    druids = DruidSupport.parse_list(@report_form.druid_list)
    Searchers::ReportByDruid.call(druids:, fields: @report_form.fields, rows:, stream:)
  end

  def set_report_form
    @report_form = ReportForm.new(report_params)
  end
end
