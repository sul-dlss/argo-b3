# frozen_string_literal: true

module RuboCop
  module Cop
    module ArgoB3
      # A job that rescues StandardError logs the error and notifies Honeybadger, directly or through a method
      # defined in the same file.
      #
      # @example
      #   # bad
      #   rescue StandardError => e
      #     failure!(message: e.message)
      #
      #   # good
      #   rescue StandardError => e
      #     Rails.logger.error(e.full_message)
      #     Honeybadger.notify(e)
      #
      #   # good
      #   rescue StandardError => e
      #     handle_error(e) # a method in this file that logs and notifies
      class JobRescueReporting < Base
        MSG = 'Log the rescued error (`Rails.logger.error(e.full_message)`) and notify Honeybadger ' \
              '(`Honeybadger.notify(e)`).'

        # @!method rescues_standard_error?(node)
        def_node_matcher :rescues_standard_error?, <<~PATTERN
          (resbody {nil? (array (const {nil? cbase} :StandardError))} ...)
        PATTERN

        # @!method honeybadger_notify?(node)
        def_node_matcher :honeybadger_notify?, '(send (const {nil? cbase} :Honeybadger) :notify ...)'

        # @!method rails_logger_error?(node)
        def_node_matcher :rails_logger_error?, '(send (send (const {nil? cbase} :Rails) :logger) :error ...)'

        def on_resbody(node)
          return unless rescues_standard_error?(node)
          return if reports?(node.body)

          add_offense(node.loc.keyword)
        end

        private

        def reports?(body)
          return false unless body

          sends = [body, *called_method_bodies(body)].compact.flat_map { |node| sends_in(node) }
          sends.any? { |send_node| honeybadger_notify?(send_node) } &&
            sends.any? { |send_node| rails_logger_error?(send_node) }
        end

        def sends_in(node)
          [node, *node.each_descendant].select(&:send_type?)
        end

        # Bodies of methods defined in this file that the rescue body calls, e.g., `handle_error(e)`.
        def called_method_bodies(body)
          called = sends_in(body).reject(&:receiver).map(&:method_name)
          processed_source.ast.each_descendant(:def).select { |def_node| called.include?(def_node.method_name) }
                          .map(&:body)
        end
      end
    end
  end
end
