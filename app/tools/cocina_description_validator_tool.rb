# frozen_string_literal: true

class CocinaDescriptionValidatorTool < RubyLLM::Tool
  description 'Validates Cocina Description JSON.'

  param :description, desc: 'Description', type: :object

  def initialize(original_cocina_description_hash:)
    @original_cocina_description_hash = original_cocina_description_hash.stringify_keys
    super()
  end

  def execute(description:)
    description_hash = description.is_a?(String) ? JSON.parse(description) : description
    return { valid: false, error: 'Provide updated description' } if description_hash.blank?

    Rails.logger.info "CocinaDescriptionValidatorTool: #{description}"
    Rails.logger.info "CocinaDescriptionValidatorTool: #{description_hash}"

    Cocina::Models::Description.new(original_cocina_description_hash.merge(description_hash))
    { valid: true, error: nil }
  rescue Cocina::Models::ValidationError => e
    Rails.logger.info "CocinaDescriptionValidatorTool: #{e.message}"
    { valid: false, error: e.message }
  end

  private

  attr_reader :original_cocina_description_hash
end
