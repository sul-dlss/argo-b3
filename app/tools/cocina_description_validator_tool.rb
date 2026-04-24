class CocinaDescriptionValidatorTool < RubyLLM::Tool
  description 'Validates Cocina Description JSON.'

  param :cocina_description, desc: 'Cocina Description JSON', type: :object

  def initialize(original_cocina_description_hash:)
    @original_cocina_description_hash = original_cocina_description_hash.stringify_keys
    super()
  end

  def execute(cocina_description:)
    cocina_description_hash = cocina_description.is_a?(String) ? JSON.parse(cocina_description) : cocina_description
    Cocina::Models::Description.new(original_cocina_description_hash.merge(cocina_description_hash))
    { valid: true, error: nil }
  rescue Cocina::Models::ValidationError => e
    { valid: false, error: e.message }
  end

  private

  attr_reader :original_cocina_description_hash
end
