# frozen_string_literal: true

# Convert CSV to JSON for registration
class RegistrationCsvConverter
  include Dry::Monads[:result]

  CONTENT_TYPES = [Cocina::Models::ObjectType.book,
                   Cocina::Models::ObjectType.document,
                   Cocina::Models::ObjectType.file,
                   Cocina::Models::ObjectType.geo,
                   Cocina::Models::ObjectType.image,
                   Cocina::Models::ObjectType.map,
                   Cocina::Models::ObjectType.media,
                   Cocina::Models::ObjectType.three_dimensional,
                   Cocina::Models::ObjectType.webarchive_binary,
                   Cocina::Models::ObjectType.webarchive_seed].freeze

  # @param [String] csv_string CSV string
  # @return [Array<Result>] a list of registration requests suitable for passing off to dor-services-client
  def self.convert(csv_string:, params: {})
    new(csv_string:, params:).convert
  end

  attr_reader :csv_string, :params

  # @param [String] csv_string CSV string
  # @param [Hash] params that can be used instead of CSV columns. Keys are same as column headers.
  def initialize(csv_string:, params:)
    @csv_string = csv_string
    @params = params
  end

  # @return [Dry::Monads::Result] an array of results with success value that is a Hash
  #   with :cocina_object, :workflow_name, and :tags
  def convert
    CSV.parse(csv_string, headers: true).map { |row| convert_row(row) }
  end

  def convert_row(row)
    cocina_object = Cocina::Models::RequestDRO.new(model_params(row))
    Success(cocina_object:,
            workflow_name: params[:initial_workflow] || row.fetch('initial_workflow'),
            tags: tags(row) + ticket_tags(row))
  rescue Cocina::Models::ValidationError => e
    Failure(e)
  end

  def model_params(row)
    {
      type: content_type(row),
      version: 1,
      label: label(row),
      administrative: administrative(row),
      identification: identification(row)
    }.tap do |model_params|
      model_params[:structural] = structural(row)
      model_params[:access] = access(row)
      project_name = params[:project_name] || row['project_name']
      model_params[:administrative][:partOfProject] = project_name if project_name.present?
    end
  end

  def label(row)
    row['folio_instance_hrid'] ? row['label'] : row.fetch('label')
  end

  def administrative(row)
    {
      hasAdminPolicy: params[:administrative_policy_object] || row.fetch('administrative_policy_object')
    }
  end

  def identification(row)
    {
      sourceId: row.fetch('source_id'),
      barcode: row['barcode'],
      catalogLinks: catalog_links(row)
    }.compact
  end

  def content_type(row)
    dro_type(params[:content_type] || row.fetch('content_type'))
  end

  def catalog_links(row)
    if row['folio_instance_hrid']
      [{ catalog: 'folio', catalogRecordId: row['folio_instance_hrid'],
         refresh: true }]
    else
      []
    end
  end

  def tags(row)
    params[:tags].presence || values_from_repeating_column(row, 'tags')
  end

  def ticket_tags(row)
    tickets = params[:tickets].presence || values_from_repeating_column(row, 'tickets')
    tickets.map { |tag| "Ticket : #{tag}" }
  end

  def values_from_repeating_column(row, column_name)
    [].tap do |values|
      count = row.headers.count(column_name)
      count.times { |n| values << row.field(column_name, n + row.index(column_name)) }
    end.compact
  end

  def dro_type(content_type) # rubocop:disable Metrics/CyclomaticComplexity, Metrics/AbcSize, Metrics/MethodLength
    # for CSV registration, we already have the URI
    return content_type if CONTENT_TYPES.include?(content_type)

    case content_type.downcase
    when 'image'
      Cocina::Models::ObjectType.image
    when '3d'
      Cocina::Models::ObjectType.three_dimensional
    when 'map'
      Cocina::Models::ObjectType.map
    when 'media'
      Cocina::Models::ObjectType.media
    when 'document'
      Cocina::Models::ObjectType.document
    when /^manuscript/
      Cocina::Models::ObjectType.manuscript
    when 'book', 'book (ltr)', 'book (rtl)'
      Cocina::Models::ObjectType.book
    when 'geo'
      Cocina::Models::ObjectType.geo
    when 'webarchive-seed'
      Cocina::Models::ObjectType.webarchive_seed
    when 'webarchive-binary'
      Cocina::Models::ObjectType.webarchive_binary
    else
      Cocina::Models::ObjectType.object
    end
  end

  def structural(row)
    {}.tap do |structural|
      collection = params[:collection] || row['collection']
      structural[:isMemberOf] = [collection] if collection
      reading_order = params[:reading_order] || row['reading_order']
      structural[:hasMemberOrders] = [{ viewingDirection: reading_order }] if reading_order.present?
    end
  end

  def access(row)
    {}.tap do |access|
      access[:view] = view_access(row)
      access[:download] = download_access(row)
      if [access[:view], access[:download]].include?('location-based')
        access[:location] = (params[:rights_location] || row.fetch('rights_location'))
      end
    end.compact
  end

  def view_access(row)
    params[:rights_view] || row['rights_view']
  end

  def download_access(row)
    params[:rights_download] || row['rights_download'] || ('none' if %w[citation-only dark].include? view_access(row))
  end
end
