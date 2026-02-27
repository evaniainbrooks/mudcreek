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

ActiveRecord::Schema[8.1].define(version: 2026_02_27_131247) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "action_text_rich_texts", force: :cascade do |t|
    t.text "body"
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "record_id", null: false
    t.string "record_type", null: false
    t.datetime "updated_at", null: false
    t.index ["record_type", "record_id", "name"], name: "index_action_text_rich_texts_uniqueness", unique: true
  end

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

  create_table "cart_items", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "listing_id", null: false
    t.bigint "tenant_id", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["listing_id"], name: "index_cart_items_on_listing_id"
    t.index ["tenant_id"], name: "index_cart_items_on_tenant_id"
    t.index ["user_id", "listing_id"], name: "index_cart_items_on_user_id_and_listing_id", unique: true
    t.index ["user_id"], name: "index_cart_items_on_user_id"
  end

  create_table "listings", force: :cascade do |t|
    t.integer "acquisition_price_cents"
    t.datetime "created_at", null: false
    t.bigint "lot_id"
    t.string "name", null: false
    t.bigint "owner_id", null: false
    t.integer "position", null: false
    t.integer "price_cents", null: false
    t.boolean "published", default: false, null: false
    t.integer "quantity", default: 1, null: false
    t.boolean "tax_exempt", default: false, null: false
    t.bigint "tenant_id", null: false
    t.datetime "updated_at", null: false
    t.index ["lot_id"], name: "index_listings_on_lot_id"
    t.index ["owner_id"], name: "index_listings_on_owner_id"
    t.index ["tenant_id", "position"], name: "index_listings_on_tenant_id_and_position", unique: true
    t.index ["tenant_id"], name: "index_listings_on_tenant_id"
    t.check_constraint "acquisition_price_cents >= 0", name: "listings_acquisition_price_cents_non_negative"
    t.check_constraint "price_cents >= 0", name: "listings_price_cents_non_negative"
    t.check_constraint "quantity >= 0", name: "listings_quantity_non_negative"
  end

  create_table "listings_categories", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "tenant_id", null: false
    t.datetime "updated_at", null: false
    t.index ["tenant_id"], name: "index_listings_categories_on_tenant_id"
  end

  create_table "listings_category_assignments", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "listing_id", null: false
    t.bigint "listings_category_id", null: false
    t.datetime "updated_at", null: false
    t.index ["listing_id", "listings_category_id"], name: "idx_on_listing_id_listings_category_id_11916b414d", unique: true
    t.index ["listing_id"], name: "index_listings_category_assignments_on_listing_id"
    t.index ["listings_category_id"], name: "index_listings_category_assignments_on_listings_category_id"
  end

  create_table "lots", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.string "number"
    t.bigint "owner_id", null: false
    t.bigint "tenant_id", null: false
    t.datetime "updated_at", null: false
    t.index ["owner_id"], name: "index_lots_on_owner_id"
    t.index ["tenant_id"], name: "index_lots_on_tenant_id"
  end

  create_table "permissions", force: :cascade do |t|
    t.string "action", null: false
    t.datetime "created_at", null: false
    t.string "resource", null: false
    t.bigint "role_id", null: false
    t.bigint "tenant_id", null: false
    t.datetime "updated_at", null: false
    t.index ["role_id", "resource", "action"], name: "index_permissions_on_role_id_and_resource_and_action", unique: true
    t.index ["role_id"], name: "index_permissions_on_role_id"
    t.index ["tenant_id"], name: "index_permissions_on_tenant_id"
  end

  create_table "roles", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "description"
    t.string "name"
    t.bigint "tenant_id", null: false
    t.datetime "updated_at", null: false
    t.index ["tenant_id"], name: "index_roles_on_tenant_id"
  end

  create_table "sessions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "ip_address"
    t.datetime "updated_at", null: false
    t.string "user_agent"
    t.bigint "user_id", null: false
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "tenants", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.boolean "default", default: false, null: false
    t.string "key", null: false
    t.datetime "updated_at", null: false
    t.index ["default"], name: "index_tenants_on_default_true", unique: true, where: "(\"default\" = true)"
    t.index ["key"], name: "index_tenants_on_key", unique: true
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email_address", null: false
    t.string "first_name", null: false
    t.string "last_name", null: false
    t.string "password_digest", null: false
    t.bigint "role_id"
    t.bigint "tenant_id", null: false
    t.datetime "updated_at", null: false
    t.index "lower((email_address)::text)", name: "index_users_on_lower_email_address", unique: true
    t.index ["role_id"], name: "index_users_on_role_id"
    t.index ["tenant_id"], name: "index_users_on_tenant_id"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "cart_items", "listings"
  add_foreign_key "cart_items", "tenants"
  add_foreign_key "cart_items", "users"
  add_foreign_key "listings", "lots"
  add_foreign_key "listings", "tenants"
  add_foreign_key "listings", "users", column: "owner_id"
  add_foreign_key "listings_categories", "tenants"
  add_foreign_key "listings_category_assignments", "listings"
  add_foreign_key "listings_category_assignments", "listings_categories"
  add_foreign_key "lots", "tenants"
  add_foreign_key "lots", "users", column: "owner_id"
  add_foreign_key "permissions", "roles"
  add_foreign_key "permissions", "tenants"
  add_foreign_key "roles", "tenants"
  add_foreign_key "sessions", "users"
  add_foreign_key "users", "roles"
  add_foreign_key "users", "tenants"
end
