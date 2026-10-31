# frozen_string_literal: true

require 'rubocop'
require 'rubocop/rspec/support'
require_relative '../../../../../lib/rubocop/cop/argo_b3/job_rescue_reporting'

RSpec.describe RuboCop::Cop::ArgoB3::JobRescueReporting, :config do
  it 'registers an offense when rescuing StandardError without logging and notifying' do
    expect_offense(<<~RUBY)
      def perform
        work
      rescue StandardError => e
      ^^^^^^ Log the rescued error (`Rails.logger.error(e.full_message)`) and notify Honeybadger (`Honeybadger.notify(e)`).
        Honeybadger.notify(e)
      end
    RUBY
  end

  it 'registers an offense for a bare rescue without logging and notifying' do
    expect_offense(<<~RUBY)
      def perform
        work
      rescue => e
      ^^^^^^ Log the rescued error (`Rails.logger.error(e.full_message)`) and notify Honeybadger (`Honeybadger.notify(e)`).
        Rails.logger.error(e.full_message)
      end
    RUBY
  end

  it 'registers an offense for an empty rescue' do
    expect_offense(<<~RUBY)
      def perform
        work
      rescue StandardError
      ^^^^^^ Log the rescued error (`Rails.logger.error(e.full_message)`) and notify Honeybadger (`Honeybadger.notify(e)`).
      end
    RUBY
  end

  it 'does not register an offense when the rescue logs and notifies' do
    expect_no_offenses(<<~RUBY)
      def perform
        work
      rescue StandardError => e
        failure!(message: e.message)
        Rails.logger.error(e.full_message)
        Honeybadger.notify(e, context: { druid: 'druid:bc123df4567' })
      end
    RUBY
  end

  it 'does not register an offense when a method in the file logs and notifies' do
    expect_no_offenses(<<~RUBY)
      def perform
        work
      rescue StandardError => e
        handle_error(e)
      end

      def handle_error(error)
        Rails.logger.error(error.full_message)
        Honeybadger.notify(error)
      end
    RUBY
  end

  it 'does not register an offense when rescuing a specific error' do
    expect_no_offenses(<<~RUBY)
      def perform
        work
      rescue Dor::Services::Client::NotFoundResponse
        nil
      end
    RUBY
  end
end
