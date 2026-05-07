# frozen_string_literal: true

# Controller for chats about structural metadata.
class StructuralChatsController < ApplicationController
  before_action :set_cocina_object

  def show
    authorize! @cocina_object, with: ObjectPolicy
    @chat = StructuralChat.find(params[:id])
    @file_sets = last_file_sets
    @structural_form = StructuralForm.new

    return if @chat.messages.exists?(role: 'user')

    StructuralChatResponseJob.perform_later(chat: @chat,
                                            prompt: 'What is the structural JSON representation for this book?')
  end

  def new
    authorize! @cocina_object, with: ObjectPolicy

    @structural_form = StructuralForm.new
    # chat = BookStructuralAgent.create!(druid: @druid, user: current_user)
    # redirect_to object_structural_chat_path(@druid, chat)
  end

  def create
    authorize! @cocina_object, with: ObjectPolicy

    @structural_form = StructuralForm.new(structural_form_params)
    if @structural_form.valid?
      chat = BookStructuralAgent.create!(
        druid: @druid,
        user: current_user
      )
      chat.with_instructions(@structural_form.instructions, append: true) if @structural_form.instructions.present?
      chat.with_instructions("The file names are:\n\n#{@structural_form.filenames}", append: true)
      redirect_to object_structural_chat_path(@druid, chat)
    else
      render :new, status: :unprocessable_content
    end
  end

  private

  def set_cocina_object
    @druid = params[:druid]
    @cocina_object = Sdr::Repository.find(druid: @druid)
  end

  def structural_form_params
    params.expect(structural_form: %i[content_type filenames instructions])
  end

  def last_file_sets
    message = @chat.messages
                   .where(role: 'assistant')
                   .where.not(content_raw: nil)
                   .where('content_raw::jsonb ? :key', key: 'structured_json_representation')
                   .reorder(created_at: :desc)
                   .first
    return [] unless message

    JSON.parse(message.content_raw['structured_json_representation']).map(&:deep_symbolize_keys)
  end
end
