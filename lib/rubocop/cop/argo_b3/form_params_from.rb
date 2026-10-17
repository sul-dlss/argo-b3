# frozen_string_literal: true

module RuboCop
  module Cop
    module ArgoB3
      # Controllers read a form's submitted params with `Form.params_from(params)`, which uses the form's param key,
      # keeps nested attributes, and returns {} when absent.
      #
      # @example
      #   # bad
      #   params.permit(item: NewItemForm.permitted_params)[:item]
      #   params.expect(mount: MountForm.permitted_params)
      #
      #   # good
      #   NewItemForm.params_from(params)
      class FormParamsFrom < Base
        MSG = 'Read form params with `Form.params_from(params)` rather than `permitted_params`.'
        RESTRICT_ON_SEND = %i[permitted_params].freeze

        def on_send(node)
          add_offense(node.loc.selector)
        end
      end
    end
  end
end
