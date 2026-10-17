# frozen_string_literal: true

# Add your own tasks in files placed in lib/tasks ending in .rake.

require_relative 'config/application'

Rails.application.load_tasks

begin
  require 'rubocop/rake_task'
  RuboCop::RakeTask.new

  desc 'Run erblint against ERB files'
  task erblint: :environment do
    puts 'Running ERB linter...'
    sh('bin/erb_lint --lint-all --format compact')
  end

  desc 'Run linter against JS files'
  task eslint: :environment do
    puts 'Running JS linter...'
    sh('yarn run lint')
  end

  desc 'Run linter against style files'
  task stylelint: :environment do
    puts 'Running style linter...'
    sh('yarn run stylelint')
  end

  desc 'Run herb against ERB files'
  task herb: :environment do
    puts 'Running ERB linter...'
    sh('bin/herb analyze app --no-timing')
  end

  desc 'Run all configured linters, reporting every failing linter'
  task lint: :environment do
    # sh raises RuntimeError and RuboCop aborts (SystemExit) on failure; keep going so every linter reports.
    failed_linters = %w[rubocop erblint eslint stylelint herb].filter_map do |linter|
      Rake::Task[linter].invoke
      nil
    rescue RuntimeError, SystemExit
      linter
    end
    abort("Linters failed: #{failed_linters.join(', ')}") if failed_linters.any?
  end

  # clear the default task injected by rspec
  task(:default).clear

  task default: %i[lint spec]
rescue LoadError
  # should only be here when gem group development and test aren't installed
end
