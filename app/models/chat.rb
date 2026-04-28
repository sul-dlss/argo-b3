class Chat < ApplicationRecord
  acts_as_chat

  def last_description(except: nil)
    messages.where(role: 'assistant').order(created_at: :desc).find_each do |message|
      next if except.present? && message.id == except.id
      next if message.content.blank?

      content = JSON.parse(message.content)
      return JSON.parse(content['description']) if content['description'].present?
    rescue JSON::ParserError
      # Skip it.
      next
    end
    nil
  end
end
