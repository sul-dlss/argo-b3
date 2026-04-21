# frozen_string_literal: true

class ChatResponseJob < ApplicationJob
  def perform(chat_id:, content:, druid:)
    @druid = druid
    # chat = Chat.find(chat_id)
    # cocina_object = Sdr::Repository.find(druid:)
    # property = 'title'

    @chat = Chat.find(chat_id)
    agent = CocinaDescriptionEditorAgent.new(
      chat:,
      persist_instructions: true
    )
    # @chat = CocinaDescriptionEditorAgent.find(chat_id)
    assistant_message = nil
    if chat.messages.where(role: 'user').empty?
      message = CocinaDescriptionClassifierAgent.new.ask(content)
      field = message.content['field']

      if field == 'none'
        assistant_message = chat.messages.create!(
          role: 'assistant',
          content: { message: "I couldn't figure out which field to change. Can you please clarify?" }.to_json
        )
        broadcast_assistant_message(assistant_message)
        broadcast_new_message_form
        return
      end
      if %w[geographic marcEncodedData purl].include?(field)
        assistant_message = chat.messages.create!(
          role: 'assistant',
          content: { message: "Changing #{field} isn't supported." }.to_json
        )
        broadcast_assistant_message(assistant_message)
        broadcast_remove_new_message_spinner
        return
      end

      assistant_message = chat.messages.create!(
        role: 'assistant',
        content: { message: "OK, updating the #{field.pluralize}." }.to_json
      )

      # CocinaDescriptionEditorAgent.sync_instructions!(chat) # persist base agent instructions
      #       instructions do
      #   [
      #     prompt('instructions'),
      #     prompt('common')
      #   ].join("\n\n")
      # end

      # field_instructions = CocinaDescriptionEditorAgent.render_prompt(field, chat:, inputs: {}, locals: {})
      chat.with_instructions(build_instructions('instructions'))
      chat.with_instructions(build_instructions(field), append: true)
      chat.with_instructions(build_instructions('description'), append: true) if %w[form contributor identifier
                                                                                    note relatedResource subject title].include?(field)
      chat.with_instructions(
        build_instructions('cocina_description',
                           locals: { cocina_description_hash: original_cocina_description_hash.slice(field.to_sym) }), append: true
      )

      # attachment = ActionDispatch::Http::UploadedFile.new(
      #   tempfile: StringIO.new(original_cocina_description_hash.slice(field.to_sym).to_json),
      #   type: 'application/json',
      #   filename: 'cocina_description.json'
      # )
      # attachment = StringIO.new(original_cocina_description_hash.slice(field.to_sym).to_json)
      # chat = CocinaDescriptionEditorAgent.find(
      #   chat_id,
      #   original_cocina_description_hash: cocina_object.description.to_h,
      #   field:
      # )
      # CocinaDescriptionClassifierAgent.sync_instructions!(chat)

      # content = "#{content}\n\nCocina description JSON: #{original_cocina_description_hash.slice(field.to_sym).to_json}"
    end

    message = @chat.create_user_message(content)

    broadcast_user_message(message)
    broadcast_assistant_message(assistant_message) if assistant_message.present?

    #     <%= turbo_stream.append "messages" do %>
    #   <%= render partial: 'messages/user', locals: { user: @message } %>
    # <% end %>

    # Turbo::StreamsChannel.broadcast_append_to(
    #   "chat_#{chat.id}",
    #   target: 'messages',
    #   partial: 'messages/user',
    #   locals: { user: message }
    # )

    complete_with_validation_retry(agent)
    message = chat.messages.last

    broadcast_assistant_message(message)
    broadcast_new_message_form
    broadcast_cocina_description_card(message)
    broadcast_purl_preview_card(message)
    broadcast_spreadsheet_card(message)
    broadcast_recent_system_and_tool_messages
  rescue Cocina::Models::ValidationError => e
    assistant_message = chat.messages.create!(
      role: 'assistant',
      content: { message: "I'm stuck on this validation error: #{e}. Can you help me understand what's wrong?" }.to_json
    )
    broadcast_assistant_message(assistant_message)
    broadcast_new_message_form
  rescue StandardError => e
    Rails.logger.error "Error in ChatResponseJob: #{e.message}"
    Honeybadger.notify(e, context: { chat_id:, druid: })
    assistant_message = chat.messages.create!(
      role: 'assistant',
      content: { message: "Sorry, something went wrong: #{e.message}" }.to_json
    )
    broadcast_assistant_message(assistant_message)
    broadcast_new_message_form
  end

  private

  attr_reader :druid, :chat

  def original_cocina_description_hash
    @original_cocina_description_hash ||= original_cocina_object.description.to_h
  end

  def original_cocina_object
    @original_cocina_object ||= Sdr::Repository.find(druid:)
  end

  def complete_with_validation_retry(agent, retries: 1)
    retry_count = 0

    begin
      start = Time.now
      response = JSON.parse(agent.complete.content)
      Rails.logger.info("ChatResponseJob response in #{Time.now - start} seconds: #{response}")
      validate_description!(JSON.parse(response['description'])) if response['description'].present?
      response
    rescue Cocina::Models::ValidationError, Dry::Struct::Error => e
      raise if retry_count >= retries

      retry_count += 1

      chat.with_instructions(
        <<~INSTRUCTIONS,
          The proposed description update was invalid. Validation error: #{e.message}
          Attempt to correct the error and return a new response in one of the accepted shapes.
          Do not repeat the invalid response.
          If the user has asked you to perform an update that is invalid or you cannot determine how to correct the error,
          ask the user for clarification on how to proceed.
        INSTRUCTIONS
        append: true
      )
      retry
    end
    #   { valid: true, error: nil }
    # rescue Cocina::Models::ValidationError => e
    #   Rails.logger.info "CocinaDescriptionValidatorTool: #{e.message}"
    #   { valid: false, error: e.message }
  end

  def validate_description!(cocina_description_hash)
    Cocina::Models::Description.new(original_cocina_description_hash.merge(cocina_description_hash))
  end

  def valid?(cocina_description_hash)
    Cocina::Models::Description.new(original_cocina_description_hash.merge(cocina_description_hash))
    true
  rescue Cocina::Models::ValidationError
    false
  end

  def build_instructions(name, locals: {})
    CocinaDescriptionEditorAgent.render_prompt(name, chat:, inputs: {}, locals:)
  end

  def broadcast_assistant_message(message)
    content = JSON.parse(message.content)
    diffs = if content['description'].present?
              description = JSON.parse(content['description'])
              previous_description = message.previous_description
              previous_description ||= original_cocina_description_hash.deep_stringify_keys.slice(*description.keys)
              Hashdiff.diff(
                CocinaDisplay::Utils.deep_compact_blank(previous_description),
                CocinaDisplay::Utils.deep_compact_blank(description)
              )
            end
    Turbo::StreamsChannel.broadcast_append_to(
      "chat_#{message.chat_id}",
      target: 'messages',
      partial: 'messages/assistant',
      locals: { assistant: message, diffs: }
    )
  end

  def broadcast_user_message(message)
    Turbo::StreamsChannel.broadcast_append_to(
      "chat_#{message.chat_id}",
      target: 'messages',
      partial: 'messages/user',
      locals: { user: message }
    )
  end

  def broadcast_recent_system_and_tool_messages
    chat.recent_system_and_tool_messages.each do |message|
      if message.role == 'tool'
        Turbo::StreamsChannel.broadcast_append_to(
          "chat_#{message.chat_id}",
          target: 'system-and-tool-messages',
          partial: 'messages/tool_results/default',
          locals: { message: }
        )
      else
        Turbo::StreamsChannel.broadcast_append_to(
          "chat_#{message.chat_id}",
          target: 'system-and-tool-messages',
          partial: 'messages/system',
          locals: { message: }
        )
      end
    end
  end

  def broadcast_new_message_form
    Turbo::StreamsChannel.broadcast_replace_to(
      "chat_#{chat.id}",
      target: 'new_message',
      partial: 'messages/form',
      locals: { message: chat.messages.build, druid: }
    )
  end

  def broadcast_remove_new_message_spinner
    Turbo::StreamsChannel.broadcast_remove_to(
      "chat_#{chat.id}",
      target: 'new_message'
    )
  end

  def broadcast_cocina_description_card(message)
    content = JSON.parse(message.content)
    return if content['description'].blank?

    content_description_hash = JSON.parse(content['description'])

    Turbo::StreamsChannel.broadcast_replace_to(
      "chat_#{chat.id}",
      target: 'cocina-description-card',
      renderable: DescriptionEditor::CocinaDescriptionCardComponent.new(
        cocina_description_hash: original_cocina_description_hash.deep_stringify_keys.merge(content_description_hash)
      ),
      layout: false,
      method: :morph
    )
  end

  def broadcast_spreadsheet_card(message)
    content = JSON.parse(message.content)
    return if content['description'].blank?

    content_description_hash = JSON.parse(content['description'])

    Turbo::StreamsChannel.broadcast_replace_to(
      "chat_#{chat.id}",
      target: 'spreadsheet-card',
      renderable: DescriptionEditor::SpreadsheetCardComponent.new(
        spreadsheet_hash: DescriptiveCsv::Export.export(source_id: original_cocina_object.identification.sourceId,
                                                        description: original_cocina_description_hash.deep_stringify_keys.merge(content_description_hash))
      ),
      layout: false,
      method: :morph
    )
  end

  def broadcast_purl_preview_card(message)
    content = JSON.parse(message.content)
    return if content['description'].blank?

    content_description_hash = JSON.parse(content['description'])
    cocina_description_hash = original_cocina_description_hash.deep_stringify_keys.merge(content_description_hash)
    cocina_hash = original_cocina_object.to_h.merge(description: cocina_description_hash)

    purl_preview = PurlPreviewService.call(cocina_hash:).then do |body|
      Nokogiri::HTML(body).css('main').inner_html.html_safe
    end

    Turbo::StreamsChannel.broadcast_replace_to(
      "chat_#{chat.id}",
      target: 'purl-preview-card',
      renderable: DescriptionEditor::PurlPreviewCardComponent.new(
        purl_preview:,
        cocina_description_hash:
      ),
      layout: false,
      method: :morph
    )
  end
end
