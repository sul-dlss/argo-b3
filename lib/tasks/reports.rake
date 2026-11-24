# frozen_string_literal: true

namespace :reports do
  # One-off sweep for issue #1571. It reads only: it doesn't open versions, save objects, or start workflows.
  desc 'Write a CSV of the DROs whose Content errors would block a Deposit (args: path, processes; default 4)'
  task :content_errors, %i[path processes] => :environment do |_task, args| # rubocop:disable Metrics/BlockLength
    path = args.fetch(:path)
    druid_slices = Searchers::DroDruidSlices.new(slice_size: 25)
    checked_count = 0
    error_count = 0
    started_at = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    progress = lambda do
      total_count = druid_slices.total_count
      elapsed = Process.clock_gettime(Process::CLOCK_MONOTONIC) - started_at
      remaining_minutes = (elapsed / checked_count * [total_count - checked_count, 0].max / 60).round
      "#{checked_count} of #{total_count} checked (#{(100.0 * checked_count / total_count).round(1)}%), " \
        "#{error_count} with errors, about #{ActiveSupport::Duration.build(remaining_minutes * 60).inspect} remaining"
    end

    CSV.open(path, 'w') do |csv|
      csv << %w[druid content_type errors]
      # Flushed before forking, or each worker writes the buffered header again when it exits.
      csv.flush
      # The parent pages Solr and writes the CSV; the workers check the slices and return their rows.
      record = lambda do |druids, _index, rows|
        rows.each { |row| csv << row }
        csv.flush
        checked_count += druids.size
        error_count += rows.size
        puts progress.call if (checked_count % 1000).zero?
      end
      Parallel.each(-> { druid_slices.next || Parallel::Stop },
                    in_processes: Integer(args.fetch(:processes, 4)), finish: record) do |druids|
        Reports::ContentErrorsSliceChecker.call(druids:)
      end
    end

    puts "Done: #{checked_count} checked, #{error_count} with errors or that could not be checked, written to #{path}"
  end
end
