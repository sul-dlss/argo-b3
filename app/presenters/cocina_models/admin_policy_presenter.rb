# frozen_string_literal: true

module CocinaModels
  # Presenter for an AdminPolicy cocina model.
  # It will delegate to the AdminPolicy model.
  # Initialize with: CocinaModels::AdminPolicyPresenter.new(admin_policy),
  # where admin_policy is a CocinaModels::AdminPolicy.
  class AdminPolicyPresenter < BasePresenter
    def display_access_rights
      "View: #{humanize_access_value(access_view)}"
    end

    def read_restricted
      return 'yes' if Permission.permission_type_read_restricted.exists?(target_druid: druid)

      'no'
    end

    def item_count
      Searchers::QueryCount.call(query: "#{Search::Fields::APO_DRUID}:\"#{druid}\" AND " \
                                        "#{Search::Fields::OBJECT_TYPES}:\"item\"")
    end

    def collection_count
      Searchers::QueryCount.call(query: "#{Search::Fields::APO_DRUID}:\"#{druid}\" AND " \
                                        "#{Search::Fields::OBJECT_TYPES}:\"collection\"")
    end
  end
end
