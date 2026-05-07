class ToolCall < ApplicationRecord
  acts_as_tool_call message: :structural_message
end
