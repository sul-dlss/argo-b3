# frozen_string_literal: true

module RuboCop
  module Cop
    module ArgoB3
      # Displayed dates and times use `format_datetime`, which converts to Pacific time and uses `time.formats`.
      #
      # @example
      #   # bad
      #   created_at.strftime('%Y-%m-%d')
      #   created_at.to_fs(:long)
      #
      #   # good
      #   format_datetime(created_at, format: :date_only)
      #   helpers.format_datetime(created_at)
      #   count.to_fs(:delimited)
      class FormatDatetime < Base
        MSG = 'Render dates and times with `format_datetime` and a format from `time.formats`.'
        RESTRICT_ON_SEND = %i[strftime to_fs to_formatted_s].freeze
        # Number formats, which to_fs also accepts.
        NUMBER_FORMATS = %i[currency delimited human human_size percentage phone rounded].freeze

        def on_send(node)
          return if number_format?(node)

          add_offense(node.loc.selector)
        end
        alias on_csend on_send

        private

        def number_format?(node)
          return false if node.method?(:strftime)

          format = node.first_argument
          format&.sym_type? && NUMBER_FORMATS.include?(format.value)
        end
      end
    end
  end
end
