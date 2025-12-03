# frozen_string_literal: true

module Search
  # Constants for search queries
  module Queries
    LAST_DAY = '[NOW-1DAY/DAY TO *]'
    LAST_WEEK = '[NOW-7DAY/DAY TO *]'
    LAST_MONTH = '[NOW-1MONTH/DAY TO *]'
    LAST_YEAR = '[NOW-1YEAR/DAY TO *]'
    MORE_THAN_WEEK_AGO = '[* TO NOW/DAY-7DAYS]'
    MORE_THAN_MONTH_AGO = '[* TO NOW/DAY-30DAYS]'
    ALL = '[* TO *]'
  end
end
