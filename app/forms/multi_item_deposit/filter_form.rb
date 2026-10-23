# frozen_string_literal: true

module MultiItemDeposit
  # Form object for filtering Multi-Item Deposits.
  # The hidden fields for the selects submit a blank value, so that deselecting all options
  # can be distinguished from the default of all options.
  class FilterForm < ApplicationForm
    attribute :statuses, array: true, default: -> { MultiItemDepositAction::DISPLAY_STATUSES.keys }
    attribute :submitted_date, :string, default: 'all'
    attribute :user_ids, array: true

    # @param user [User] the current user, whose Multi-Item Deposits are the default for user_ids
    # @param admin [Boolean] whether the Multi-Item Deposits are filtered by user
    def initialize(attributes = {}, user: nil, admin: false, **keyword_attributes)
      @user = user
      @admin = admin
      super(attributes.merge(keyword_attributes))
      # The default is the current user, which an attribute default cannot reference.
      self.user_ids ||= [user.id.to_s] if user
    end

    attr_reader :user

    def admin? = @admin

    # @return [Hash] the params of the filters that limit the Multi-Item Deposits
    def active_filter_params
      {
        statuses: (statuses unless all_statuses?),
        submitted_date: (submitted_date unless all_submitted_dates?),
        user_ids: (user_ids if admin? && !default_user_ids?)
      }.compact
    end

    # @return [Hash] the filters for MultiItemDepositAction.filtered, with nil for no limit
    def filters
      { statuses: statuses_filter, submitted_since:, user_ids: user_ids_filter }
    end

    # @return [Array<String>,nil] the display statuses to filter by, or nil when all statuses are selected
    def statuses_filter
      selected_statuses unless all_statuses?
    end

    # @return [Array<String>,nil] the user ids to filter by, or nil when not an admin or all users are selected
    def user_ids_filter
      selected_user_ids if admin? && !all_users?
    end

    # @return [ActiveSupport::TimeWithZone, nil] the start of the submitted date range,
    #   or nil when not limited (View all or an unknown submitted date)
    def submitted_since
      BulkActions::FilterForm::SUBMITTED_DATES.dig(submitted_date, 1)&.ago
    end

    # @return [Array<Array(String, String)>] label and display status pairs for the statuses select
    def status_options
      MultiItemDepositAction::DISPLAY_STATUSES.map { |status, label| [label, status] }
    end

    # @return [Array<Array(String, String)>] label and key pairs for the submitted date select
    def submitted_date_options
      BulkActions::FilterForm::SUBMITTED_DATES.map { |key, (label, _duration)| [label, key] }
    end

    # @return [Array<Array(String, String)>] sunetid and user id pairs for the users select,
    #   with the current user first followed by the other users with Multi-Item Deposits
    def user_options
      @user_options ||= ([user] + other_users.sort_by(&:sunetid))
                        .map { |option_user| [option_user.sunetid, option_user.id.to_s] }
    end

    private

    def selected_statuses
      statuses.compact_blank
    end

    def all_statuses?
      (MultiItemDepositAction::DISPLAY_STATUSES.keys - selected_statuses).empty?
    end

    def other_users
      User.where(id: MultiItemDepositAction.select(:user_id)).where.not(id: user.id)
    end

    def selected_user_ids
      user_ids.compact_blank
    end

    def all_users?
      (user_options.map(&:last) - selected_user_ids).empty?
    end

    def default_user_ids?
      selected_user_ids == [user.id.to_s]
    end

    def all_submitted_dates?
      submitted_since.nil?
    end
  end
end
