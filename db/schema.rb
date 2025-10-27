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

ActiveRecord::Schema[8.1].define(version: 2025_10_18_001000) do
  create_table "active_storage_attachments", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.string "identified", default: "no", null: false
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
    t.string "identified", default: "no", null: false
    t.string "key", null: false
    t.text "metadata"
    t.string "service_name", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "food_logs", force: :cascade do |t|
    t.integer "calories"
    t.integer "carbs_g"
    t.datetime "created_at", null: false
    t.integer "fats_g"
    t.string "food_name"
    t.string "image_url"
    t.integer "protein_g"
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["created_at"], name: "index_food_logs_on_created_at"
    t.index ["user_id"], name: "index_food_logs_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.integer "activity_level", default: 1, null: false
    t.datetime "created_at", null: false
    t.integer "daily_calories_goal"
    t.integer "daily_carbs_goal_g"
    t.integer "daily_fats_goal_g"
    t.integer "daily_protein_goal_g"
    t.date "date_of_birth"
    t.string "email"
    t.string "goal_type", default: "maintain", null: false
    t.integer "height_cm"
    t.string "provider"
    t.string "sex"
    t.boolean "survey_completed", default: false, null: false
    t.string "uid"
    t.datetime "updated_at", null: false
    t.string "username"
    t.float "weight_kg"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["uid"], name: "index_users_on_uid"
    t.index ["username"], name: "index_users_on_username", unique: true
  end

  add_foreign_key "food_logs", "users"
end
