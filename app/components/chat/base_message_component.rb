# frozen_string_literal: true

class Chat::BaseMessageComponent < ApplicationComponent
  def initialize(message:)
    @message = message
    super()
  end

  attr_reader :message

  def role
    message.role.capitalize
  end
end
