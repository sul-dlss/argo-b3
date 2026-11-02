# frozen_string_literal: true

module RuboCop
  module Cop
    module ArgoB3
      # An `ActiveSupport::Concern` defines its instance methods in the module body, not inside `included do`.
      #
      # @example
      #   # bad
      #   included do
      #     def title
      #       'Title'
      #     end
      #   end
      #
      #   # good
      #   included do
      #     validates :title, presence: true
      #   end
      #
      #   def title
      #     'Title'
      #   end
      class ConcernIncludedMethods < Base
        MSG = 'Define concern methods in the module body, not inside `included do`.'

        # @!method included_block?(node)
        def_node_matcher :included_block?, '(block (send nil? :included) (args) $_)'

        def on_block(node)
          body = included_block?(node)
          return unless body

          (body.begin_type? ? body.children : [body]).select(&:def_type?).each do |def_node|
            add_offense(def_node.loc.keyword.join(def_node.loc.name))
          end
        end
      end
    end
  end
end
