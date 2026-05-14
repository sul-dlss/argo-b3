# frozen_string_literal: true

# Concern for controllers that need to handle tokens.
module TokenConcern
  extend ActiveSupport::Concern

  #   Controller can set:
  #     self.token_purpose = 'download'
  #     self.token_expires_at_builder = -> { 2.hours.from_now }
  included do
    class_attribute :token_purpose, default: 'default'
    # Using fixed expires at keeps the token constant to avoid interfering with morphing.
    class_attribute :token_expires_at_builder, default: -> { 1.week.from_now.end_of_day }
  end

  def verifier
    Rails.application.message_verifier(:argo)
  end

  # @return [String] a token that can be used to verify the druid
  def generate_token(value)
    verifier.generate(value, purpose: self.class.token_purpose,
                             expires_at: self.class.token_expires_at_builder.call)
  end

  # @return [String] the value if the token is valid, otherwise raises an error
  # @raise [ActiveSupport::MessageVerifier::InvalidSignature] if the token is invalid
  def verify_token(token)
    verifier.verify(token, purpose: self.class.token_purpose)
  end
end
