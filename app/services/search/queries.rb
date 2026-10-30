# frozen_string_literal: true

module Search
  # Constants for search queries
  module Queries
    # Rounding (/DAY, /YEAR) is in the time zone of the Solr request's TZ param (see Search::ItemQueryBuilder).
    TODAY = '[NOW/DAY TO *]'
    LAST_7_DAYS = '[NOW/DAY-7DAYS TO *]'
    LAST_30_DAYS = '[NOW/DAY-30DAYS TO *]'
    YEAR_TO_DATE = '[NOW/YEAR TO *]'
    # N calendar days counting today, from midnight today.
    NEXT_7_DAYS = '[NOW/DAY TO NOW/DAY+7DAYS}'
    NEXT_30_DAYS = '[NOW/DAY TO NOW/DAY+30DAYS}'
    NEXT_YEAR = '[NOW/DAY TO NOW/DAY+1YEAR}'
    MORE_THAN_WEEK_AGO = '[* TO NOW/DAY-7DAYS]'
    MORE_THAN_MONTH_AGO = '[* TO NOW/DAY-30DAYS]'
    ALL = '[* TO *]'
  end
end
