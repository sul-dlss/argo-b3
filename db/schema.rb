# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_05_05_181437) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "bulk_actions", force: :cascade do |t|
    t.string "action_type", null: false
    t.datetime "created_at", null: false
    t.text "description"
    t.integer "druid_count_fail", default: 0, null: false
    t.integer "druid_count_success", default: 0, null: false
    t.integer "druid_count_total", default: 0, null: false
    t.string "status", default: "created", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["user_id"], name: "index_bulk_actions_on_user_id"
  end

  create_table "models", force: :cascade do |t|
    t.jsonb "capabilities", default: []
    t.integer "context_window"
    t.datetime "created_at", null: false
    t.string "family"
    t.date "knowledge_cutoff"
    t.integer "max_output_tokens"
    t.jsonb "metadata", default: {}
    t.jsonb "modalities", default: {}
    t.datetime "model_created_at"
    t.string "model_id", null: false
    t.string "name", null: false
    t.jsonb "pricing", default: {}
    t.string "provider", null: false
    t.datetime "updated_at", null: false
    t.index ["capabilities"], name: "index_models_on_capabilities", using: :gin
    t.index ["family"], name: "index_models_on_family"
    t.index ["modalities"], name: "index_models_on_modalities", using: :gin
    t.index ["provider", "model_id"], name: "index_models_on_provider_and_model_id", unique: true
    t.index ["provider"], name: "index_models_on_provider"
  end

  create_table "structural_chats", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "druid", null: false
    t.bigint "model_id"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["druid"], name: "index_structural_chats_on_druid"
    t.index ["model_id"], name: "index_structural_chats_on_model_id"
    t.index ["user_id"], name: "index_structural_chats_on_user_id"
  end

  create_table "structural_messages", force: :cascade do |t|
    t.integer "cache_creation_tokens"
    t.integer "cached_tokens"
    t.text "content"
    t.json "content_raw"
    t.datetime "created_at", null: false
    t.integer "input_tokens"
    t.bigint "model_id"
    t.integer "output_tokens"
    t.string "role", null: false
    t.bigint "structural_chat_id", null: false
    t.text "thinking_signature"
    t.text "thinking_text"
    t.integer "thinking_tokens"
    t.bigint "tool_call_id"
    t.datetime "updated_at", null: false
    t.index ["model_id"], name: "index_structural_messages_on_model_id"
    t.index ["role"], name: "index_structural_messages_on_role"
    t.index ["structural_chat_id"], name: "index_structural_messages_on_structural_chat_id"
    t.index ["tool_call_id"], name: "index_structural_messages_on_tool_call_id"
  end

  create_table "tool_calls", force: :cascade do |t|
    t.jsonb "arguments", default: {}
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "structural_message_id", null: false
    t.text "thought_signature"
    t.string "tool_call_id", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_tool_calls_on_name"
    t.index ["structural_message_id"], name: "index_tool_calls_on_structural_message_id"
    t.index ["tool_call_id"], name: "index_tool_calls_on_tool_call_id", unique: true
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email_address", null: false
    t.string "groups", default: [], array: true
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.index ["email_address"], name: "index_users_on_email_address", unique: true
  end

  add_foreign_key "bulk_actions", "users"
  add_foreign_key "structural_chats", "models"
  add_foreign_key "structural_chats", "users"
  add_foreign_key "structural_messages", "models"
  add_foreign_key "structural_messages", "structural_chats"
  add_foreign_key "structural_messages", "tool_calls"
  add_foreign_key "tool_calls", "structural_messages"
end
