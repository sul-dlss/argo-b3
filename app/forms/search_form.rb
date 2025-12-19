# frozen_string_literal: true

# Search form
class SearchForm < ApplicationForm
  attribute :query, :string
  attribute :include_google_books, :boolean, default: false
  attribute :page, :integer, default: 1
  attribute :debug, :boolean, default: false
  attribute :sort, :string

  # Facet fields
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

  def blank?
    attributes.except('include_google_books', 'page', 'debug', 'sort').values.all?(&:blank?)
  end

  # @return [hash] this form's attributes merged with new_attrs
  # new_attrs take precedence for scalar values; arrays are merged_attrs
  def with_attributes(new_attrs) # rubocop:disable Metrics/AbcSize
    attributes.with_indifferent_access.tap do |merged_attrs|
      new_attrs.each do |key, value|
        if merged_attrs[key].is_a?(Array)
          if value.is_a?(Array)
            merged_attrs[key] = (merged_attrs[key] + value).uniq
          else
            merged_attrs[key] << value unless merged_attrs[key].include?(value) || value.nil?
          end
        else
          merged_attrs[key] = value
        end
      end
    end
  end

  # @return [hash] this form's attributes with provided attrs removed
  def without_attributes(without_attrs)
    attributes.with_indifferent_access.tap do |new_attrs|
      without_attrs.each do |key, value|
        if new_attrs[key].is_a?(Array) && value.present?
          new_attrs[key] = new_attrs[key] - Array(value)
        elsif new_attrs[key] == value || value.nil?
          new_attrs[key] = nil
        end
      end
    end.compact
  end

  # @param key [String, Symbol] the attribute name
  # @param value [String, Integer, Symbol, nil] the attribute value or nil to match any value
  # @return [boolean] whether the given key/value is selected in this form
  def selected?(key:, value: nil)
    attrs = attributes.with_indifferent_access
    norm_value = value.is_a?(Symbol) ? value.to_s : value
    if attrs[key].is_a?(Array)
      value.nil? ? attrs[key].any? : attrs[key].include?(norm_value)
    else
      value.nil? ? attrs[key].present? : attrs[key] == norm_value
    end
  end

  def attributes
    # This drops attributes with false values so that they are not included in URLs.
    super.compact_blank
  end

  def facet_attributes
    attributes.except('include_google_books', 'page', 'debug', 'query', 'sort')
  end

  # @return [Array<Array(String, String)>] current filters as attribute name/value pairs
  def current_filters
    @current_filters ||= [].tap do |filters|
      filters << ['query', query] if query.present?
      filters << ['include_google_books', true] if include_google_books
      facet_attributes.each do |attr_name, values|
        Array(values).map do |value|
          filters << [attr_name, value]
        end
      end
    end
  end

  # @return [Boolean] whether any facets are selected
  def facets_selected?
    facet_attributes.values.any?(&:present?)
  end

  def to_s
    Search::Serializer.call(search_form: self)
  end
end
