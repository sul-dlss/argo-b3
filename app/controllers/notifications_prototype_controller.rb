# frozen_string_literal: true

# PROTOTYPE (throwaway, never merge): renders notification UI variants from in-memory sample data.
class NotificationsPrototypeController < ApplicationController
  skip_verify_authorized

  Notification = Struct.new(:outcome, :title, :text, :subject_label, :subject_kind, :created_at, :emailed,
                            keyword_init: true)

  EMAIL_KINDS = [
    ['File Check finished', 'A Multi-Item Deposit you started has finished File Check, with or without errors.'],
    ['Multi-Item Deposit settled', 'Every MID Item Deposit of a Multi-Item Deposit you started is Complete or In Error.'],
    ['Deposit failed', 'A Single-Object Deposit you started is In Error.'],
    ['Bulk Action deposits finished with errors', 'The Bulk Action Object Deposits of a Bulk Action you ran settled with errors.']
  ].freeze

  def index
    @notifications = params[:empty] ? [] : sample_notifications
    @email_kinds = EMAIL_KINDS
  end

  def settings
    @email_kinds = EMAIL_KINDS
  end

  private

  def sample_notifications = self.class.sample

  def self.sample # rubocop:disable Metrics/MethodLength
    now = Time.zone.now
    [
      Notification.new(outcome: :error, title: 'Deposit failed', subject_kind: :item,
                       subject_label: 'Map of the Bay Area, 1906 (bc123df4567)', created_at: now - 4.minutes,
                       text: 'gisAssemblyWF:extract-iso19139-metadata: Missing ESRI metadata files'),
      Notification.new(outcome: :success, title: 'File Check finished', subject_kind: :mid,
                       subject_label: 'Multi-Item Deposit 42 (Rumsey maps batch 12)', created_at: now - 38.minutes,
                       text: 'No errors. Ready for Deposit Initiation.'),
      Notification.new(outcome: :info, title: 'Discovery finished', subject_kind: :mid,
                       subject_label: 'Multi-Item Deposit 42 (Rumsey maps batch 12)', created_at: now - 1.hour,
                       text: '2 warnings.'),
      Notification.new(outcome: :error, title: 'Bulk Action finished with errors', subject_kind: :bulk_action,
                       subject_label: 'Bulk action 311 (Apply APO defaults)', created_at: now - 3.hours,
                       text: '3 of 120 objects failed.'),
      Notification.new(outcome: :success, title: 'Deposit complete', subject_kind: :item,
                       subject_label: 'Oral history: Jane Doe (dd111ff2222)', created_at: now - 1.day),
      Notification.new(outcome: :error, title: 'Multi-Item Deposit settled with errors', subject_kind: :mid,
                       subject_label: 'Multi-Item Deposit 39 (Parker manuscripts)', created_at: now - 2.days,
                       text: '4 of 250 MID Item Deposits In Error: bb111cc2222 (accessionWF:shelve), …'),
      Notification.new(outcome: :error, title: 'Deposit Initiation found errors', subject_kind: :mid,
                       subject_label: 'Multi-Item Deposit 40 (Hoover posters)', created_at: now - 3.days,
                       text: 'Object changed since discovery for 2 MID Item Deposits.'),
      Notification.new(outcome: :success, title: 'Multi-Item Deposit complete', subject_kind: :mid,
                       subject_label: 'Multi-Item Deposit 37 (Rumsey maps batch 11)', created_at: now - 9.days),
      Notification.new(outcome: :success, title: 'Bulk Action finished', subject_kind: :bulk_action,
                       subject_label: 'Bulk action 305 (Export tags)', created_at: now - 12.days)
    ]
  end
end
