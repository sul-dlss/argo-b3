# frozen_string_literal: true

module StructuralCsv
  # Service for generating a structural metadata CSV template for a Multi-Item Deposit:
  # a row for each discovered file, pre-populated with the druid, filename, and mimetype, and with the rights from the
  # object's Object Access (as Contents::DefaultFileAccess gives them to files).
  class Template
    def self.as_csv(multi_item_deposit_action:)
      new(multi_item_deposit_action:).as_csv
    end

    # @param multi_item_deposit_action [MultiItemDepositAction]
    def initialize(multi_item_deposit_action:)
      @multi_item_deposit_action = multi_item_deposit_action
    end

    def as_csv
      CSV.generate(headers: true) do |csv|
        csv << Export::HEADERS
        rows do |row|
          csv << row
        end
      end
    end

    def rows
      # Item Deposits without a Content (e.g., with discovery errors) have no files.
      item_deposit_actions.each do |item_deposit_action|
        druid = DruidSupport.bare_druid_from(item_deposit_action.druid)
        rights = rights_values(cocina_objects[item_deposit_action.druid])
        item_deposit_action.content.content_file_binaries.path_order.each do |content_file_binary|
          yield row_for(druid:, content_file_binary:, rights:)
        end
      end
    end

    private

    attr_reader :multi_item_deposit_action

    def row_for(druid:, content_file_binary:, rights:)
      values = { 'druid' => druid, 'filename' => content_file_binary.filepath,
                 'mimetype' => content_file_binary.mime_type, **rights }
      Export::HEADERS.map { |header| values[header] }
    end

    def item_deposit_actions
      @item_deposit_actions ||= multi_item_deposit_action.item_deposit_actions.where.not(content_id: nil)
                                                         .includes(:content).order(:manifest_line_number).to_a
    end

    # Read from DSA rather than Solr (which lags), since the values become the files' access.
    # @return [Hash<String, Cocina::Models::DRO>] by druid
    def cocina_objects
      @cocina_objects ||= Sdr::Repository.find_all(druids: item_deposit_actions.map(&:druid))
    end

    # The location is blank unless the access is location-based. An object not found has blank rights.
    def rights_values(cocina_object)
      return {} unless cocina_object

      access = Contents::DefaultFileAccess.new(access: cocina_object.access).attributes
      location = access[:location] if [access[:view], access[:download]].include?('location-based')
      { 'rights_view' => access[:view], 'rights_download' => access[:download], 'rights_location' => location }
    end
  end
end
