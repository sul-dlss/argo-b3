# frozen_string_literal: true

require 'open3'
require 'shellwords'

# Runs linters with plain-text, one-line-per-offense output and ends with a summary that repeats each
# failing linter's offenses, so the tail of the output is enough to act on.
module Lint
  # changed_command lints the files it is given; files matches the paths it checks (nil: always the whole app).
  # offenses matches the lines the summary repeats (nil: the end of the output).
  Linter = Struct.new(:name, :commands, :changed_command, :files, :offenses) do
    def commands_for(changed_files)
      return commands unless changed_files && files

      paths = changed_files.grep(files)
      paths.empty? ? [] : [[changed_command, *paths.map { |path| Shellwords.escape(path) }].join(' ')]
    end

    def summary(output)
      lines = offenses ? output.lines.grep(offenses) : []
      lines.any? ? lines : output.lines.last(20)
    end
  end

  FILE_LINE_COLUMN = /:\d+:\d+: /

  LINTERS = [
    Linter.new(name: 'rubocop', commands: ['bin/rubocop --format emacs --no-color'],
               changed_command: 'bin/rubocop --format emacs --no-color --force-exclusion',
               files: /(\.(rb|rake|ru|gemspec)|Gemfile)\z/, offenses: /:\d+:\d+: [A-Z]: /),
    Linter.new(name: 'erblint', commands: ['bin/erb_lint --lint-all --format compact'],
               changed_command: 'bin/erb_lint --format compact', files: /\.erb\z/, offenses: FILE_LINE_COLUMN),
    # Herb prints failing offenses (errors) only, each file's name on its own line before them.
    Linter.new(name: 'herb', commands: ['yarn -s run herb-lint app --simple --no-color --log-level error'],
               changed_command: 'yarn -s run herb-lint --simple --no-color --log-level error',
               files: %r{\Aapp/.*\.erb\z}, offenses: /\A\S+\.erb:\Z|\A\s+\d+:\d+\s/),
    Linter.new(name: 'eslint', commands: ['yarn -s run lint'], changed_command: 'yarn -s run lint',
               files: /\.m?js\z/, offenses: FILE_LINE_COLUMN),
    Linter.new(name: 'stylelint', commands: ['yarn -s run stylelint --formatter unix --no-color'],
               changed_command: 'yarn -s run stylelint --formatter unix --no-color',
               files: %r{\Aapp/assets/stylesheets/.*\.scss\z}, offenses: FILE_LINE_COLUMN),
    Linter.new(name: 'i18n', commands: ['bundle exec i18n-tasks missing', 'bundle exec i18n-tasks unused'])
  ].freeze

  # Files changed on this branch, uncommitted, or untracked, relative to origin/main.
  def self.changed_files
    committed = `git diff --name-only --diff-filter=d origin/main...HEAD`.lines
    uncommitted = `git diff --name-only --diff-filter=d HEAD`.lines
    untracked = `git ls-files --others --exclude-standard`.lines
    (committed + uncommitted + untracked).map(&:strip).uniq.select { |path| File.file?(path) }
  end

  # Streams each command's output and returns it, with whether every command succeeded.
  def self.run(commands)
    output = +''
    success = commands.all? do |command|
      puts "$ #{command}"
      Open3.popen2e({ 'NO_COLOR' => '1', 'FORCE_COLOR' => '0' }, command) do |_stdin, out, wait|
        out.each_line do |line|
          print line
          output << line
        end
        wait.value.success?
      end
    end
    [success, output]
  end

  def self.run_all(changed_files: nil)
    $stdout.sync = true # Keep the summary ahead of abort's message on stderr.
    failures = LINTERS.filter_map do |linter|
      commands = linter.commands_for(changed_files)
      next if commands.empty?

      puts "\n== #{linter.name} =="
      success, output = run(commands)
      [linter, output] unless success
    end
    summarize(failures)
  end

  def self.summarize(failures)
    puts "\n== Summary =="
    failures.each do |linter, output|
      puts "-- #{linter.name} --", linter.summary(output)
    end
    abort("LINT FAILED: #{failures.map { |linter, _output| linter.name }.join(', ')}") if failures.any?
    puts 'LINT OK'
  end
end

namespace :lint do
  desc 'Run linters on files changed relative to origin/main (i18n-tasks always runs)'
  task changed: :environment do
    Lint.run_all(changed_files: Lint.changed_files)
  end
end

desc 'Run all configured linters, ending with a summary of every offense'
task lint: :environment do
  Lint.run_all
end

Lint::LINTERS.each do |linter|
  next if linter.name == 'rubocop' # RuboCop::RakeTask defines it.

  desc "Run #{linter.name}"
  task linter.name => :environment do
    success, = Lint.run(linter.commands)
    abort("#{linter.name} failed") unless success
  end
end
