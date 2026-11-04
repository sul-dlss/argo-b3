# frozen_string_literal: true

module CocinaObjectMutators
  # Mapper for merging a CocinaModels::Dro with an existing Cocina::Models::DROWithMetadata.
  class DroMutator < BaseMutator
    # @param file_access_overwrite [Contents::FileAccessOverwrite, nil] the form's decision to apply the access to files
    def initialize(file_access_overwrite: nil, **)
      @file_access_overwrite = file_access_overwrite
      super(**)
    end

    private

    attr_reader :file_access_overwrite

    def build_new_cocina_props # rubocop:disable Metrics/AbcSize
      super.tap do |new_cocina_props|
        new_cocina_props[:access][:view] = cocina_model.access_view
        new_cocina_props[:access][:download] = cocina_model.access_download
        new_cocina_props[:access][:location] = cocina_model.access_location
        new_cocina_props[:identification][:barcode] = cocina_model.barcode.presence
        new_cocina_props[:type] = cocina_model.content_type
        new_cocina_props[:structural] ||= {}
        new_cocina_props[:structural][:hasMemberOrders] = build_member_orders
        new_cocina_props[:structural][:isMemberOf] = cocina_model.collection_druids

        update_embargo(new_cocina_props[:access])
        update_file_access(new_cocina_props)
      end
    end

    # Updated with the access, since cocina rejects a dark object with files that are not dark.
    def update_file_access(new_cocina_props)
      return if request_object?

      # Without a form's decision (e.g., bulk rights), only dark is applied.
      overwrite = file_access_overwrite ||
                  Contents::FileAccessOverwrite.new(previous_access: cocina_object.access,
                                                    access: new_cocina_props[:access], overwrite: false)
      return unless overwrite.apply?

      overwrite.apply_to_cocina_structural!(new_cocina_props[:structural])
    end

    def update_embargo(access_hash)
      if cocina_model.embargo_release_date.blank?
        access_hash.delete(:embargo)
      else
        access_hash[:embargo] = {
          # Cocina::Models::Embargo requires a DateTime, not the Time that the attribute casts to.
          releaseDate: cocina_model.embargo_release_date.to_datetime,
          view: cocina_model.embargo_view,
          download: cocina_model.embargo_download,
          location: cocina_model.embargo_location
        }.compact
      end
    end

    def build_member_orders
      return [] if cocina_model.viewing_direction.blank?

      [{ viewingDirection: cocina_model.viewing_direction }]
    end
  end
end
