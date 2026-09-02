# frozen_string_literal: true

# Solid Cache stores cache values (e.g. Cocina hashes) by INSERTing them
# into the solid_cache_entries table. Honeybadger's SQL-obfuscation regex
# (Honeybadger::Util::SQL::SQUOTE_DATA) scans the full SQL text of every "sql.active_record"
# notification for both Insights and breadcrumbs, and on large Cocina hashes this scan
# can exceed Rails' default Regexp.timeout and raise Regexp::TimeoutError
# see https://github.com/sul-dlss/argo-b3/issues/353

# Excluding these queries via `events.ignore` would not help: that filter only decides
# whether an already-obfuscated event gets sent, so the expensive regex would still run.
# Instead, skip Honeybadger's SQL instrumentation for solid_cache_entries queries before
# obfuscation happens, while leaving Insights/breadcrumbs untouched for everything else.

require 'honeybadger/notification_subscriber'

module Honeybadger
  # Skips Insights instrumentation for solid_cache_entries queries before Honeybadger obfuscates the SQL.
  module SkipSolidCacheSqlInsights
    def process?(name, payload)
      return false if payload[:sql]&.include?('solid_cache_entries')

      super
    end
  end
end

Honeybadger::ActiveRecordSubscriber.prepend(Honeybadger::SkipSolidCacheSqlInsights)

notifications = Honeybadger::Breadcrumbs::ActiveSupport.default_notifications
default_sql_exclude_when = notifications.dig('sql.active_record', :exclude_when)
notifications['sql.active_record'][:exclude_when] = lambda do |data|
  data[:sql]&.include?('solid_cache_entries') || default_sql_exclude_when.call(data)
end

Honeybadger.configure do |config|
  config.breadcrumbs.active_support_notifications = notifications
end
