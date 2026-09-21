# frozen_string_literal: true

# Base search form.
#
# This class is abstract: instantiate ResultsSearchForm or WorkflowGridSearchForm instead. A form's
# class determines which view it represents; there is deliberately no `view` attribute.
#
# Attributes declared here determine *which objects match*. Attributes that only affect how matching
# objects are presented (e.g., page, sort) belong on a subclass.
class SearchForm < ApplicationForm
  include NormalizationConcern

  # Attributes that do not contribute to the query. Subclasses that add presentation attributes
  # should append to this.
  def self.non_query_attributes
    %w[debug]
  end

  # The route scope that this form's view is mounted under. Used to resolve facet path helpers.
  # @return [String]
  def self.route_scope
    raise NotImplementedError, "#{name} must implement .route_scope"
  end

  def self.permitted_params
    raise NotImplementedError, 'SearchForm is abstract; use a subclass' if self == SearchForm

    super
  end

  delegate :route_scope, to: :class

  # @return [Boolean] whether this search can be pinned
  def pinnable?
    false
  end

  # @return [Boolean] whether this view supports sorting search results
  def sortable?
    false
  end

  # Whether this view renders the list of item results. The primary facets (object types and
  # content types) are returned by that same query, so views that do not render item results get
  # those facets from the secondary facets request instead.
  # @return [Boolean]
  def item_results?
    false
  end

  attribute :query, :string
  attribute :debug, :boolean, default: false

  # Facet fields
  attribute :access_rights, array: true, default: -> { [] }
  attribute :access_rights_exclude, array: true, default: -> { [] }
  attribute :admin_policy_druids, array: true, default: -> { [] }
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
  attribute :formats, array: true, default: -> { [] }
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
  # This removes a blank submitted by the search bar.
  normalizes_array_compact_blank :object_types
  attribute :processing_statuses, array: true, default: -> { [] }
  attribute :projects, array: true, default: -> { [] }
  attribute :regions, array: true, default: -> { [] }
  attribute :registered_date, array: true, default: -> { [] }
  attribute :registered_date_from, :date, default: nil
  attribute :registered_date_to, :date, default: nil
  attribute :released_to_earthworks, array: true, default: -> { [] }
  attribute :released_to_purl_sitemap, array: true, default: -> { [] }
  attribute :released_to_searchworks, array: true, default: -> { [] }
  attribute :tags, array: true, default: -> { [] }
  attribute :tickets, array: true, default: -> { [] }
  attribute :topics, array: true, default: -> { [] }
  attribute :versions, array: true, default: -> { [] }
  attribute :wps_workflows, array: true, default: -> { [] }

  def blank?
    attributes.except(*self.class.non_query_attributes).values.all?(&:blank?)
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
  def without_attributes(without_attrs) # rubocop:disable Metrics/AbcSize
    attributes.with_indifferent_access.tap do |new_attrs|
      Array(without_attrs).each do |key, value|
        if new_attrs[key].is_a?(Array) && value.present?
          new_attrs[key] = new_attrs[key] - Array(value)
        elsif new_attrs[key] == value || value.nil?
          new_attrs[key] = nil
        end
      end
    end.compact
  end

  # @return [SearchForm] a new form of the same class with the provided attrs merged in
  def with(new_attrs)
    build(self.class, with_attributes(new_attrs))
  end

  # @return [SearchForm] a new form of the same class with the provided attrs removed
  def without(without_attrs)
    build(self.class, without_attributes(without_attrs))
  end

  # Converts this form to another view's form, keeping only attributes that the target class
  # declares. This is how the view toggle crosses form classes; nothing else should need it.
  # @param klass [Class] the target form class
  # @return [SearchForm]
  def as(klass)
    return self if instance_of?(klass)

    build(klass, attributes)
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
    attributes.except(*self.class.non_query_attributes, 'query')
  end

  # @return [Array<Array(String, String)>] current filters as attribute name/value pairs
  def current_filters
    @current_filters ||= [].tap do |filters|
      filters << ['query', query] if query.present?
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

  private

  # Builds a form of the given class, dropping attributes that the class does not declare.
  # Callers pass attributes that not every view has -- most commonly page, which facet links reset
  # when the filters change -- and a view that has no such attribute should simply ignore it.
  def build(klass, attrs)
    klass.new(attrs.slice(*klass.attribute_names))
  end
end
