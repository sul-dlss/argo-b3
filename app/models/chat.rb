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

  # Returns the description hash from the most recent assistant message with a description before the given message
  # (or the most recent assistant message if no message is given).
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

  # Returns system and tool messages between the two most recent assistant messages with descriptions.
  # Otherwise, returns all system and tool messages.
  # @return [ActiveRecord::Relation] the system and tool messages
  def recent_system_and_tool_messages
    assistant_messages = messages.where(role: 'assistant').select do |message|
      next false if message.content.blank?

      content = JSON.parse(message.content)
      content['description'].present?
    rescue JSON::ParserError
      false
    end
    relation = messages.where(role: %w[system tool])
    if assistant_messages.size >= 2
      start_message, end_message = assistant_messages.last(2)
      relation = relation.where(created_at: start_message.created_at..end_message.created_at)
    end
    relation
  end
end
