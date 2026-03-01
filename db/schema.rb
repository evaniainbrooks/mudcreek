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

ActiveRecord::Schema[8.1].define(version: 2026_03_01_100005) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  # Custom types defined in this database.
  # Note that some types may not work with other database engines. Be careful if changing database.
  create_enum "discount_code_type", ["fixed", "percentage"]
  create_enum "listing_pricing_type", ["firm", "negotiable"]
  create_enum "listing_state", ["on_sale", "sold", "cancelled"]
  create_enum "listing_type", ["sale", "rental"]
  create_enum "offer_state", ["pending", "accepted", "declined"]

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

  create_table "addresses", force: :cascade do |t|
    t.string "city"
    t.string "country", default: "CA"
    t.datetime "created_at", null: false
    t.string "postal_code"
    t.string "province"
    t.string "street_address"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["user_id"], name: "index_addresses_on_user_id", unique: true
  end

  create_table "cart_items", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "listing_id", null: false
    t.datetime "rental_end_at"
    t.integer "rental_price_cents"
    t.datetime "rental_start_at"
    t.bigint "tenant_id", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["listing_id"], name: "index_cart_items_on_listing_id"
    t.index ["tenant_id"], name: "index_cart_items_on_tenant_id"
    t.index ["user_id", "listing_id"], name: "index_cart_items_on_user_id_and_listing_id", unique: true
  end

  create_table "delivery_methods", force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.integer "price_cents", default: 0, null: false
    t.bigint "tenant_id", null: false
    t.datetime "updated_at", null: false
    t.index "tenant_id, lower((name)::text)", name: "index_delivery_methods_on_tenant_id_and_lower_name", unique: true
    t.check_constraint "price_cents >= 0", name: "delivery_methods_price_cents_non_negative"
  end

  create_table "discount_codes", force: :cascade do |t|
    t.integer "amount_cents", null: false
    t.datetime "created_at", null: false
    t.enum "discount_type", null: false, enum_type: "discount_code_type"
    t.datetime "end_at"
    t.string "key", null: false
    t.datetime "start_at"
    t.bigint "tenant_id", null: false
    t.datetime "updated_at", null: false
    t.index "tenant_id, lower((key)::text)", name: "index_discount_codes_on_tenant_id_and_lower_key", unique: true
    t.check_constraint "amount_cents > 0", name: "discount_codes_amount_cents_positive"
  end

  create_table "listings", force: :cascade do |t|
    t.integer "acquisition_price_cents"
    t.datetime "created_at", null: false
    t.string "hashid", null: false
    t.enum "listing_type", default: "sale", null: false, enum_type: "listing_type"
    t.bigint "lot_id"
    t.string "name", null: false
    t.bigint "owner_id", null: false
    t.integer "position", null: false
    t.integer "price_cents", null: false
    t.enum "pricing_type", default: "firm", null: false, enum_type: "listing_pricing_type"
    t.boolean "published", default: false, null: false
    t.integer "quantity", default: 1, null: false
    t.enum "state", default: "on_sale", null: false, enum_type: "listing_state"
    t.boolean "tax_exempt", default: false, null: false
    t.bigint "tenant_id", null: false
    t.datetime "updated_at", null: false
    t.index ["hashid"], name: "index_listings_on_hashid", unique: true
    t.index ["lot_id"], name: "index_listings_on_lot_id"
    t.index ["owner_id"], name: "index_listings_on_owner_id"
    t.check_constraint "acquisition_price_cents >= 0", name: "listings_acquisition_price_cents_non_negative"
    t.check_constraint "price_cents >= 0", name: "listings_price_cents_non_negative"
    t.check_constraint "quantity >= 0", name: "listings_quantity_non_negative"
    t.unique_constraint ["tenant_id", "position"], deferrable: :deferred, name: "uq_listings_tenant_position"
  end

  create_table "listings_categories", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "hashid", null: false
    t.string "name", null: false
    t.bigint "tenant_id", null: false
    t.datetime "updated_at", null: false
    t.index ["hashid"], name: "index_listings_categories_on_hashid", unique: true
    t.index ["tenant_id", "name"], name: "index_listings_categories_on_tenant_id_and_name", unique: true
  end

  create_table "listings_category_assignments", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "listing_id", null: false
    t.bigint "listings_category_id", null: false
    t.datetime "updated_at", null: false
    t.index ["listing_id", "listings_category_id"], name: "idx_on_listing_id_listings_category_id_11916b414d", unique: true
    t.index ["listings_category_id"], name: "index_listings_category_assignments_on_listings_category_id"
  end

  create_table "listings_rental_rate_plans", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "duration_minutes", null: false
    t.string "label", null: false
    t.bigint "listing_id", null: false
    t.integer "position", null: false
    t.integer "price_cents", null: false
    t.bigint "tenant_id", null: false
    t.datetime "updated_at", null: false
    t.index ["listing_id", "position"], name: "index_listings_rental_rate_plans_on_listing_id_and_position"
    t.index ["tenant_id"], name: "index_listings_rental_rate_plans_on_tenant_id"
    t.check_constraint "duration_minutes > 0", name: "listings_rental_rate_plans_duration_minutes_positive"
    t.check_constraint "price_cents >= 0", name: "listings_rental_rate_plans_price_cents_nonneg"
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

  create_table "offers", force: :cascade do |t|
    t.integer "amount_cents", null: false
    t.datetime "created_at", null: false
    t.bigint "listing_id", null: false
    t.string "message"
    t.enum "state", default: "pending", null: false, enum_type: "offer_state"
    t.bigint "tenant_id", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["listing_id"], name: "index_offers_on_listing_id"
    t.index ["listing_id"], name: "index_offers_on_listing_id_where_accepted", unique: true, where: "(state = 'accepted'::offer_state)"
    t.index ["tenant_id"], name: "index_offers_on_tenant_id"
    t.index ["user_id"], name: "index_offers_on_user_id"
    t.check_constraint "amount_cents > 0", name: "offers_amount_cents_positive"
  end

  create_table "permissions", force: :cascade do |t|
    t.string "action", null: false
    t.datetime "created_at", null: false
    t.string "resource", null: false
    t.bigint "role_id", null: false
    t.bigint "tenant_id", null: false
    t.datetime "updated_at", null: false
    t.index ["role_id", "resource", "action"], name: "index_permissions_on_role_id_and_resource_and_action", unique: true
    t.index ["tenant_id"], name: "index_permissions_on_tenant_id"
  end

  create_table "rental_bookings", force: :cascade do |t|
    t.bigint "cart_item_id", null: false
    t.datetime "created_at", null: false
    t.datetime "end_at", null: false
    t.datetime "expires_at", null: false
    t.bigint "listing_id", null: false
    t.datetime "start_at", null: false
    t.bigint "tenant_id", null: false
    t.datetime "updated_at", null: false
    t.index ["cart_item_id"], name: "index_rental_bookings_on_cart_item_id", unique: true
    t.index ["expires_at"], name: "index_rental_bookings_on_expires_at"
    t.index ["listing_id", "start_at", "end_at"], name: "index_rental_bookings_on_listing_id_and_start_at_and_end_at"
    t.index ["tenant_id"], name: "index_rental_bookings_on_tenant_id"
  end

  create_table "roles", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "description", null: false
    t.string "name", null: false
    t.bigint "tenant_id", null: false
    t.datetime "updated_at", null: false
    t.index "tenant_id, lower((name)::text)", name: "index_roles_on_tenant_id_and_lower_name", unique: true
  end

  create_table "sessions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "ip_address"
    t.datetime "updated_at", null: false
    t.string "user_agent"
    t.bigint "user_id", null: false
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "solid_cable_messages", force: :cascade do |t|
    t.binary "channel", null: false
    t.bigint "channel_hash", null: false
    t.datetime "created_at", null: false
    t.binary "payload", null: false
    t.index ["channel"], name: "index_solid_cable_messages_on_channel"
    t.index ["channel_hash"], name: "index_solid_cable_messages_on_channel_hash"
    t.index ["created_at"], name: "index_solid_cable_messages_on_created_at"
  end

  create_table "solid_cache_entries", force: :cascade do |t|
    t.integer "byte_size", null: false
    t.datetime "created_at", null: false
    t.binary "key", null: false
    t.bigint "key_hash", null: false
    t.binary "value", null: false
    t.index ["byte_size"], name: "index_solid_cache_entries_on_byte_size"
    t.index ["key_hash", "byte_size"], name: "index_solid_cache_entries_on_key_hash_and_byte_size"
    t.index ["key_hash"], name: "index_solid_cache_entries_on_key_hash", unique: true
  end

  create_table "solid_queue_blocked_executions", force: :cascade do |t|
    t.string "concurrency_key", null: false
    t.datetime "created_at", null: false
    t.datetime "expires_at", null: false
    t.bigint "job_id", null: false
    t.integer "priority", default: 0, null: false
    t.string "queue_name", null: false
    t.index ["concurrency_key", "priority", "job_id"], name: "index_solid_queue_blocked_executions_for_release"
    t.index ["expires_at", "concurrency_key"], name: "index_solid_queue_blocked_executions_for_maintenance"
    t.index ["job_id"], name: "index_solid_queue_blocked_executions_on_job_id", unique: true
  end

  create_table "solid_queue_claimed_executions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "job_id", null: false
    t.bigint "process_id"
    t.index ["job_id"], name: "index_solid_queue_claimed_executions_on_job_id", unique: true
    t.index ["process_id", "job_id"], name: "index_solid_queue_claimed_executions_on_process_id_and_job_id"
  end

  create_table "solid_queue_failed_executions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "error"
    t.bigint "job_id", null: false
    t.index ["job_id"], name: "index_solid_queue_failed_executions_on_job_id", unique: true
  end

  create_table "solid_queue_jobs", force: :cascade do |t|
    t.string "active_job_id"
    t.text "arguments"
    t.string "class_name", null: false
    t.string "concurrency_key"
    t.datetime "created_at", null: false
    t.datetime "finished_at"
    t.integer "priority", default: 0, null: false
    t.string "queue_name", null: false
    t.datetime "scheduled_at"
    t.datetime "updated_at", null: false
    t.index ["active_job_id"], name: "index_solid_queue_jobs_on_active_job_id"
    t.index ["class_name"], name: "index_solid_queue_jobs_on_class_name"
    t.index ["finished_at"], name: "index_solid_queue_jobs_on_finished_at"
    t.index ["queue_name", "finished_at"], name: "index_solid_queue_jobs_for_filtering"
    t.index ["scheduled_at", "finished_at"], name: "index_solid_queue_jobs_for_alerting"
  end

  create_table "solid_queue_pauses", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "queue_name", null: false
    t.index ["queue_name"], name: "index_solid_queue_pauses_on_queue_name", unique: true
  end

  create_table "solid_queue_processes", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "hostname"
    t.string "kind", null: false
    t.datetime "last_heartbeat_at", null: false
    t.text "metadata"
    t.string "name", null: false
    t.integer "pid", null: false
    t.bigint "supervisor_id"
    t.index ["last_heartbeat_at"], name: "index_solid_queue_processes_on_last_heartbeat_at"
    t.index ["name", "supervisor_id"], name: "index_solid_queue_processes_on_name_and_supervisor_id", unique: true
    t.index ["supervisor_id"], name: "index_solid_queue_processes_on_supervisor_id"
  end

  create_table "solid_queue_ready_executions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "job_id", null: false
    t.integer "priority", default: 0, null: false
    t.string "queue_name", null: false
    t.index ["job_id"], name: "index_solid_queue_ready_executions_on_job_id", unique: true
    t.index ["priority", "job_id"], name: "index_solid_queue_poll_all"
    t.index ["queue_name", "priority", "job_id"], name: "index_solid_queue_poll_by_queue"
  end

  create_table "solid_queue_recurring_executions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "job_id", null: false
    t.datetime "run_at", null: false
    t.string "task_key", null: false
    t.index ["job_id"], name: "index_solid_queue_recurring_executions_on_job_id", unique: true
    t.index ["task_key", "run_at"], name: "index_solid_queue_recurring_executions_on_task_key_and_run_at", unique: true
  end

  create_table "solid_queue_recurring_tasks", force: :cascade do |t|
    t.text "arguments"
    t.string "class_name"
    t.string "command", limit: 2048
    t.datetime "created_at", null: false
    t.text "description"
    t.string "key", null: false
    t.integer "priority", default: 0
    t.string "queue_name"
    t.string "schedule", null: false
    t.boolean "static", default: true, null: false
    t.datetime "updated_at", null: false
    t.index ["key"], name: "index_solid_queue_recurring_tasks_on_key", unique: true
    t.index ["static"], name: "index_solid_queue_recurring_tasks_on_static"
  end

  create_table "solid_queue_scheduled_executions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "job_id", null: false
    t.integer "priority", default: 0, null: false
    t.string "queue_name", null: false
    t.datetime "scheduled_at", null: false
    t.index ["job_id"], name: "index_solid_queue_scheduled_executions_on_job_id", unique: true
    t.index ["scheduled_at", "priority", "job_id"], name: "index_solid_queue_dispatch_all"
  end

  create_table "solid_queue_semaphores", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "expires_at", null: false
    t.string "key", null: false
    t.datetime "updated_at", null: false
    t.integer "value", default: 1, null: false
    t.index ["expires_at"], name: "index_solid_queue_semaphores_on_expires_at"
    t.index ["key", "value"], name: "index_solid_queue_semaphores_on_key_and_value"
    t.index ["key"], name: "index_solid_queue_semaphores_on_key", unique: true
  end

  create_table "tenants", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "currency", default: "CAD", null: false
    t.boolean "default", default: false, null: false
    t.string "key", null: false
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.index ["default"], name: "index_tenants_on_default_true", unique: true, where: "(\"default\" = true)"
    t.index ["key"], name: "index_tenants_on_key", unique: true
  end

  create_table "users", force: :cascade do |t|
    t.datetime "activated_at"
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
  add_foreign_key "addresses", "users"
  add_foreign_key "cart_items", "listings"
  add_foreign_key "cart_items", "tenants"
  add_foreign_key "cart_items", "users"
  add_foreign_key "delivery_methods", "tenants"
  add_foreign_key "discount_codes", "tenants"
  add_foreign_key "listings", "lots", on_delete: :nullify
  add_foreign_key "listings", "tenants"
  add_foreign_key "listings", "users", column: "owner_id"
  add_foreign_key "listings_categories", "tenants"
  add_foreign_key "listings_category_assignments", "listings"
  add_foreign_key "listings_category_assignments", "listings_categories"
  add_foreign_key "listings_rental_rate_plans", "listings"
  add_foreign_key "listings_rental_rate_plans", "tenants"
  add_foreign_key "lots", "tenants"
  add_foreign_key "lots", "users", column: "owner_id"
  add_foreign_key "offers", "listings"
  add_foreign_key "offers", "tenants"
  add_foreign_key "offers", "users"
  add_foreign_key "permissions", "roles"
  add_foreign_key "permissions", "tenants"
  add_foreign_key "rental_bookings", "cart_items", on_delete: :cascade
  add_foreign_key "rental_bookings", "listings"
  add_foreign_key "rental_bookings", "tenants"
  add_foreign_key "roles", "tenants"
  add_foreign_key "sessions", "users"
  add_foreign_key "solid_queue_blocked_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_claimed_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_failed_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_ready_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_recurring_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_scheduled_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "users", "roles"
  add_foreign_key "users", "tenants"
end
