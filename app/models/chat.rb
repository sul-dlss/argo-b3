# frozen_string_literal: true

class Chat < ApplicationRecord
  acts_as_chat

  # def last_description(except: nil)
  #   messages.where(role: 'assistant').order(created_at: :desc).find_each do |message|
  #     next if except.present? && message.id == except.id
  #     next if message.content.blank?

  #     content = JSON.parse(message.content)
  #     return JSON.parse(content['description']) if content['description'].present?
  #   rescue JSON::ParserError
  #     # Skip it.
  #     next
  #   end
  #   nil
  # end

  # @param before [Message] the description must be retrieved for a message before the given message
  # @return [Hash, nil] the description hash or nil if not found
  def description_before(before: nil)
    relation = messages.where(role: 'assistant').order(created_at: :desc)
    relation = relation.where(created_at: ...before.created_at) if before.present?

    relation.find_each do |message|
      next if message.content.blank?

      content = JSON.parse(message.content)
      return JSON.parse(content['description']) if content['description'].present?
    rescue JSON::ParserError
      # Skip it.
      next
    end
    nil
  end

  def last_description
    description_before
  end
end
