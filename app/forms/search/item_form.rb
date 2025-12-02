# frozen_string_literal: true

module Search
  # Form for searching items (DROs, collections, or APOs)
  class ItemForm < Search::Form
    attribute :access_rights, array: true, default: -> { [] }
    attribute :access_rights_exclude, array: true, default: -> { [] }
    attribute :admin_policy_titles, array: true, default: -> { [] }
    attribute :collection_titles, array: true, default: -> { [] }
    attribute :content_types, array: true, default: -> { [] }
    attribute :dates, array: true, default: -> { [] }
    attribute :earliest_accessioned_date, array: true, default: -> { [] }
    attribute :earliest_accessioned_date_from, :date, default: nil
    attribute :earliest_accessioned_date_to, :date, default: nil
    attribute :embargo_release_date, array: true, default: -> { [] }
    attribute :embargo_release_date_from, :date, default: nil
    attribute :embargo_release_date_to, :date, default: nil
    attribute :file_roles, array: true, default: -> { [] }
    attribute :genres, array: true, default: -> { [] }
    attribute :identifiers, array: true, default: -> { [] }
    attribute :languages, array: true, default: -> { [] }
    attribute :licenses, array: true, default: -> { [] }
    attribute :last_accessioned_date, array: true, default: -> { [] }
    attribute :last_accessioned_date_from, :date, default: nil
    attribute :last_accessioned_date_to, :date, default: nil
    attribute :last_opened_date, array: true, default: -> { [] }
    attribute :last_opened_date_from, :date, default: nil
    attribute :last_opened_date_to, :date, default: nil
    attribute :last_published_date, array: true, default: -> { [] }
    attribute :last_published_date_from, :date, default: nil
    attribute :last_published_date_to, :date, default: nil
    attribute :metadata_sources, array: true, default: -> { [] }
    attribute :mimetypes, array: true, default: -> { [] }
    attribute :mods_resource_types, array: true, default: -> { [] }
    attribute :object_types, array: true, default: -> { [] }
    attribute :processing_statuses, array: true, default: -> { [] }
    attribute :projects, array: true, default: -> { [] }
    attribute :regions, array: true, default: -> { [] }
    attribute :registered_date, array: true, default: -> { [] }
    attribute :registered_date_from, :date, default: nil
    attribute :registered_date_to, :date, default: nil
    attribute :released_to_earthworks, array: true, default: -> { [] }
    attribute :released_to_purl_sitemap, array: true, default: -> { [] }
    attribute :released_to_searchworks, array: true, default: -> { [] }
    attribute :sw_resource_types, array: true, default: -> { [] }
    attribute :tags, array: true, default: -> { [] }
    attribute :tickets, array: true, default: -> { [] }
    attribute :topics, array: true, default: -> { [] }
    attribute :versions, array: true, default: -> { [] }
    attribute :wps_workflows, array: true, default: -> { [] }

    # @return [Hash] attributes defined on this class (not its superclasses)
    def this_attributes
      attributes.slice(*self.class.this_attribute_names)
    end

    delegate :this_attribute_names, to: :class

    # @return [Array<Array(String, String)>] current filters as attribute name/value pairs
    def current_filters
      @current_filters ||= begin
        filters = self.class.this_attribute_names.flat_map do |attr_name|
          values = public_send(attr_name)
          Array(values).map do |value|
            [attr_name, value]
          end
        end
        super + filters
      end
    end

    class << self
      # @return [Array<String>] attribute names defined on this class (not its superclasses)
      def this_attribute_names
        attribute_names - superclass.attribute_names
      end
    end
  end
end
