# frozen_string_literal: true

module Search
  # Converts a search form into a human-readable string
  class Serializer
    include ApplicationHelper

    def self.call(...)
      new(...).call
    end

    def initialize(search_form:)
      @search_form = search_form
    end

    def call
      (query_parts + multi_item_deposit_parts + facet_parts).join(' AND ')
    end

    private

    attr_reader :search_form

    def query_parts
      [quote(search_form.query)].compact_blank
    end

    def multi_item_deposit_parts
      search_form.multi_item_deposit_action_ids.map { |id| "#{facet_label(:multi_item_deposit_action_ids)}: #{id}" }
    end

    def facet_parts
      Search::ItemQueryBuilder::FACETS.flat_map do |facet_config|
        if facet_config.dynamic_facet.present?
          dynamic_facet_part_for(facet_config:)
        else
          value_facet_parts_for(facet_config:)
        end
      end.compact
    end

    # @return [Array<String, nil>] the parts for the selected, excluded, and year range values of a value facet
    def value_facet_parts_for(facet_config:)
      [facet_part_for(facet_config:)].tap do |parts|
        parts << facet_part_for(facet_config:, exclude: true) if facet_config.exclude_form_field.present?
        parts << year_range_part_for(facet_config:) if facet_config.year_from_form_field.present?
      end
    end

    def facet_part_for(facet_config:, exclude: false)
      form_field = exclude ? facet_config.exclude_form_field : facet_config.form_field
      return if search_form.public_send(form_field).blank?

      values = search_form.public_send(form_field).map do |value|
        quote(Search::Facets.missing_value?(value) ? facet_value_label(value) : value)
      end
      combine_label_and_values(facet_config:, values:, exclude:)
    end

    def dynamic_facet_part_for(facet_config:)
      date_from_value = date_from_value_for(facet_config:)
      date_to_value = date_to_value_for(facet_config:)
      form_values = search_form.public_send(facet_config.form_field)

      return if [form_values, date_from_value, date_to_value].all?(&:blank?)

      values = form_values.map { |value| quote(facet_value_label(value)) }
      values << combine_dates(date_from_value:, date_to_value:) if [date_from_value, date_to_value].any?(&:present?)
      combine_label_and_values(facet_config:, values:)
    end

    def year_range_part_for(facet_config:)
      year_from_value = search_form.public_send(facet_config.year_from_form_field)
      year_to_value = search_form.public_send(facet_config.year_to_form_field)
      return if year_from_value.nil? && year_to_value.nil?

      year_range = combine_dates(date_from_value: year_from_value, date_to_value: year_to_value)
      "#{facet_label(facet_config.form_field)}: #{year_range}"
    end

    def combine_label_and_values(facet_config:, values:, exclude: false)
      label = facet_label(facet_config.form_field)
      if values.one?
        "#{label}: #{'NOT ' if exclude}#{values.first}"
      else
        "#{label}: #{'NOT ' if exclude}(#{values.join(" #{facet_config.operator.upcase} ")})"
      end
    end

    def combine_dates(date_from_value:, date_to_value:)
      "#{date_from_value || '*'} TO #{date_to_value || '*'}"
    end

    def date_from_value_for(facet_config:)
      return if facet_config.date_from_form_field.blank?

      search_form.public_send(facet_config.date_from_form_field)
    end

    def date_to_value_for(facet_config:)
      return if facet_config.date_to_form_field.blank?

      search_form.public_send(facet_config.date_to_form_field)
    end

    def quote(str)
      return if str.blank?

      %("#{str}")
    end
  end
end
