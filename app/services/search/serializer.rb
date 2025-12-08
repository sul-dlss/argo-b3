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
      (query_parts + include_google_book_parts + facet_parts).join(' AND ')
    end

    private

    attr_reader :search_form

    def query_parts
      [quote(search_form.query)].compact_blank
    end

    def include_google_book_parts
      return [] unless search_form.include_google_books

      ['include Google Books']
    end

    def facet_parts
      [].tap do |parts|
        Search::ItemQueryBuilder::FACETS.each do |facet_config|
          if facet_config.dynamic_facet.present?
            parts << dynamic_facet_part_for(facet_config:)
          else
            parts << facet_part_for(facet_config:)
            parts << facet_part_for(facet_config:, exclude: true) if facet_config.exclude_form_field.present?
          end
        end
      end.compact
    end

    def facet_part_for(facet_config:, exclude: false)
      form_field = exclude ? facet_config.exclude_form_field : facet_config.form_field
      return if search_form.public_send(form_field).blank?

      values = search_form.public_send(form_field).map { |value| quote(value) }
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

    def combine_label_and_values(facet_config:, values:, exclude: false)
      label = facet_label(facet_config.form_field)
      if values.one?
        "#{label}: #{'NOT ' if exclude}#{values.first}"
      else
        "#{label}: #{'NOT ' if exclude}(#{values.join(' OR ')})"
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
