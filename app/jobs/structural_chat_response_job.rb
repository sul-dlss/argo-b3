class StructuralChatResponseJob < ApplicationJob
  def perform(chat:, prompt:)
    agent = BookStructuralAgent.new(chat:)
    agent.ask(prompt)

    Turbo::StreamsChannel.broadcast_refresh_to(
      chat,
      method: :morph,
      scroll: :preserve
    )
  end
end
