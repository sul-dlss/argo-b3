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

ActiveRecord::Schema[8.1].define(version: 2026_08_14_125042) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "active_storage_attachments", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "record_id", null: false
    t.string "record_type", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.string "content_type"
    t.datetime "created_at", null: false
    t.string "filename", null: false
    t.string "key", null: false
    t.text "metadata"
    t.string "service_name", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

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

  create_table "chats", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "model_id"
    t.datetime "updated_at", null: false
    t.index ["model_id"], name: "index_chats_on_model_id"
  end

  create_table "content_file_binaries", force: :cascade do |t|
    t.string "basename", null: false
    t.bigint "content_id", null: false
    t.datetime "created_at", null: false
    t.string "extname", null: false
    t.string "file_location", null: false
    t.string "filepath", null: false
    t.string "md5_digest"
    t.string "path_parts", default: [], null: false, array: true
    t.string "sha1_digest"
    t.bigint "size"
    t.datetime "updated_at", null: false
    t.index ["content_id", "filepath"], name: "index_content_file_binaries_on_content_id_and_filepath", unique: true
    t.index ["content_id"], name: "index_content_file_binaries_on_content_id"
  end

  create_table "content_file_sets", force: :cascade do |t|
    t.bigint "content_id", null: false
    t.datetime "created_at", null: false
    t.string "external_identifier"
    t.string "file_set_type", null: false
    t.string "label", null: false
    t.integer "position", null: false
    t.datetime "updated_at", null: false
    t.index ["content_id", "position"], name: "index_content_file_sets_on_content_id_and_position", unique: true
    t.index ["content_id"], name: "index_content_file_sets_on_content_id"
  end

  create_table "content_files", force: :cascade do |t|
    t.bigint "content_file_binary_id", null: false
    t.bigint "content_file_set_id", null: false
    t.boolean "corrected_for_accessibility", default: false, null: false
    t.datetime "created_at", null: false
    t.string "download", null: false
    t.string "external_identifier"
    t.integer "height"
    t.string "label", null: false
    t.string "language_tag"
    t.string "location"
    t.string "mime_type"
    t.integer "position", null: false
    t.boolean "preserve", null: false
    t.boolean "publish", null: false
    t.boolean "sdr_generated_text", default: false, null: false
    t.boolean "shelve", null: false
    t.datetime "updated_at", null: false
    t.string "use"
    t.string "view", null: false
    t.integer "width"
    t.index ["content_file_binary_id"], name: "index_content_files_on_content_file_binary_id"
    t.index ["content_file_set_id", "content_file_binary_id"], name: "idx_on_content_file_set_id_content_file_binary_id_6042d030c0", unique: true
    t.index ["content_file_set_id", "position"], name: "index_content_files_on_content_file_set_id_and_position", unique: true
    t.index ["content_file_set_id"], name: "index_content_files_on_content_file_set_id"
  end

  create_table "contents", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "druid", null: false
    t.boolean "immutable", default: true, null: false
    t.string "lock", null: false
    t.string "staging_state", default: "staging_not_in_progress", null: false
    t.datetime "updated_at", null: false
    t.index ["druid", "lock", "immutable"], name: "index_contents_on_druid_and_lock_and_immutable", unique: true
  end

  create_table "messages", force: :cascade do |t|
    t.integer "cache_creation_tokens"
    t.integer "cached_tokens"
    t.bigint "chat_id", null: false
    t.text "content"
    t.json "content_raw"
    t.datetime "created_at", null: false
    t.integer "input_tokens"
    t.bigint "model_id"
    t.integer "output_tokens"
    t.string "role", null: false
    t.text "thinking_signature"
    t.text "thinking_text"
    t.integer "thinking_tokens"
    t.bigint "tool_call_id"
    t.datetime "updated_at", null: false
    t.index ["chat_id"], name: "index_messages_on_chat_id"
    t.index ["model_id"], name: "index_messages_on_model_id"
    t.index ["role"], name: "index_messages_on_role"
    t.index ["tool_call_id"], name: "index_messages_on_tool_call_id"
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

  create_table "permissions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "permission_type", null: false
    t.string "target_druid"
    t.datetime "updated_at", null: false
    t.string "workgroup", null: false
    t.index ["target_druid"], name: "index_permissions_on_target_druid"
    t.index ["workgroup", "permission_type", "target_druid"], name: "idx_on_workgroup_permission_type_target_druid_05a2ba0d8f", unique: true, nulls_not_distinct: true
  end

  create_table "tool_calls", force: :cascade do |t|
    t.jsonb "arguments", default: {}
    t.datetime "created_at", null: false
    t.bigint "message_id", null: false
    t.string "name", null: false
    t.text "thought_signature"
    t.string "tool_call_id", null: false
    t.datetime "updated_at", null: false
    t.index ["message_id"], name: "index_tool_calls_on_message_id"
    t.index ["name"], name: "index_tool_calls_on_name"
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

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "bulk_actions", "users"
  add_foreign_key "chats", "models"
  add_foreign_key "content_file_binaries", "contents"
  add_foreign_key "content_file_sets", "contents"
  add_foreign_key "content_files", "content_file_binaries"
  add_foreign_key "content_files", "content_file_sets"
  add_foreign_key "messages", "chats"
  add_foreign_key "messages", "models"
  add_foreign_key "messages", "tool_calls"
  add_foreign_key "tool_calls", "messages"
end
