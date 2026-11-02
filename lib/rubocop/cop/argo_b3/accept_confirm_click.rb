# frozen_string_literal: true

module RuboCop
  module Cop
    module ArgoB3
      # A positional click inside `accept_confirm` can miss after a layout shift, so the confirm never appears
      # (Capybara::ModalNotFound). Click via JS with `click_and_accept_confirm` (spec/support/confirm_helpers.rb).
      #
      # @example
      #   # bad
      #   accept_confirm('Delete?') { click_button 'Delete' }
      #
      #   # good
      #   click_and_accept_confirm('Delete?', find_button('Delete'))
      class AcceptConfirmClick < Base
        MSG = 'Use `click_and_accept_confirm(message, find_link(...))` rather than clicking inside `accept_confirm`.'
        CLICK_METHODS = %i[click_link click_button click_on].to_set.freeze

        def on_block(node)
          return unless node.send_node.method?(:accept_confirm)

          node.body&.each_node(:send) do |send_node|
            add_offense(send_node) if CLICK_METHODS.include?(send_node.method_name)
          end
        end
        alias on_numblock on_block
      end
    end
  end
end
