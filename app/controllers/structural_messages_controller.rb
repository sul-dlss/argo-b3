# frozen_string_literal: true

class StructuralMessagesController < ApplicationController
  skip_verify_authorized # TODO: Fix this.
  before_action :set_chat

  def create
    @structural_form = StructuralForm.new(structural_form_params)
    return render :new, status: :unprocessable_content unless @structural_form.valid?

    @chat.with_instructions(@structural_form.instructions, append: true) if @structural_form.instructions.present?
    @chat.with_instructions("Additional file names:\n\n#{@structural_form.filenames}", append: true)

    StructuralChatResponseJob.perform_later(chat: @chat,
                                            prompt: @structural_form.instructions.presence || 'Add these files as an incremental update.')
  end

  private

  def set_chat
    @chat = StructuralChat.find(params[:structural_chat_id])
  end

  def structural_form_params
    params.expect(structural_form: %i[filenames instructions])
  end
end
