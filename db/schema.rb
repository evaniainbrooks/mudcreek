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

ActiveRecord::Schema[8.1].define(version: 2026_03_31_000000) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  # Custom types defined in this database.
  # Note that some types may not work with other database engines. Be careful if changing database.
  create_enum "discount_code_type", ["fixed", "percentage"]
  create_enum "invoice_status", ["unpaid", "paid"]
  create_enum "listing_pricing_type", ["firm", "negotiable"]
  create_enum "listing_state", ["on_sale", "sold", "cancelled"]
  create_enum "listing_type", ["sale", "rental"]
  create_enum "lot_state", ["submitted", "received", "auctioned", "settled", "paid"]
  create_enum "offer_state", ["pending", "accepted", "declined"]
  create_enum "settlement_line_item_type", ["hammer_price", "buyers_premium", "tax", "seller_commission", "seller_fee"]
  create_enum "social_media_platform", ["facebook", "instagram", "youtube", "twitter", "tiktok", "snapchat", "linkedin", "discord", "patreon", "onlyfans", "twitch"]
  create_enum "transaction_state", ["pending", "succeeded", "failed"]
  create_enum "user_verification_status", ["not_validated", "validated"]

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
    t.string "address_type", default: "profile", null: false
    t.bigint "addressable_id", null: false
    t.string "addressable_type", null: false
    t.string "city"
    t.string "country", default: "CA"
    t.datetime "created_at", null: false
    t.float "latitude"
    t.float "longitude"
    t.string "postal_code"
    t.string "province"
    t.string "street_address"
    t.datetime "updated_at", null: false
    t.index ["addressable_type", "addressable_id", "address_type"], name: "index_addresses_on_addressable_and_type", unique: true
  end

  create_table "auction_listings", force: :cascade do |t|
    t.bigint "auction_id", null: false
    t.datetime "created_at", null: false
    t.datetime "ends_at"
    t.integer "extension_count", default: 0, null: false
    t.string "hashid", null: false
    t.bigint "listing_id", null: false
    t.integer "position"
    t.integer "reserve_price_cents"
    t.integer "starting_bid_cents", null: false
    t.datetime "updated_at", null: false
    t.bigint "variant_id"
    t.index ["auction_id"], name: "index_auction_listings_on_auction_id"
    t.index ["ends_at"], name: "index_auction_listings_on_ends_at"
    t.index ["hashid"], name: "index_auction_listings_on_hashid", unique: true
    t.index ["listing_id", "variant_id"], name: "index_auction_listings_on_listing_id_and_variant_id", unique: true, where: "(variant_id IS NOT NULL)"
    t.index ["listing_id"], name: "index_auction_listings_on_listing_id_no_variant", unique: true, where: "(variant_id IS NULL)"
  end

  create_table "auction_registrations", force: :cascade do |t|
    t.text "admin_notes"
    t.bigint "auction_id", null: false
    t.datetime "created_at", null: false
    t.string "state", default: "pending", null: false
    t.bigint "tenant_id", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["auction_id", "user_id"], name: "index_auction_registrations_on_auction_id_and_user_id", unique: true
    t.index ["tenant_id"], name: "index_auction_registrations_on_tenant_id"
    t.index ["user_id"], name: "index_auction_registrations_on_user_id"
  end

  create_table "auctions", force: :cascade do |t|
    t.string "admin_email_address"
    t.boolean "auto_approve", default: false, null: false
    t.integer "bidding_extension", default: 0, null: false
    t.integer "buyers_premium_rate", default: 0, null: false
    t.datetime "created_at", null: false
    t.integer "end_time_stagger_interval", default: 0, null: false
    t.datetime "ends_at"
    t.string "hashid", null: false
    t.string "name", null: false
    t.boolean "published", default: false, null: false
    t.boolean "reconciled", default: false, null: false
    t.datetime "starts_at"
    t.bigint "tenant_id", null: false
    t.string "timezone", default: "Eastern Time (US & Canada)", null: false
    t.datetime "updated_at", null: false
    t.index ["hashid"], name: "index_auctions_on_hashid", unique: true
    t.index ["tenant_id"], name: "index_auctions_on_tenant_id"
  end

  create_table "bid_increment_schedules", force: :cascade do |t|
    t.bigint "auction_id"
    t.datetime "created_at", null: false
    t.bigint "tenant_id", null: false
    t.datetime "updated_at", null: false
    t.index ["auction_id"], name: "index_bid_increment_schedules_on_auction_id", unique: true
    t.index ["tenant_id"], name: "index_bid_increment_schedules_on_tenant_id"
  end

  create_table "bid_increment_tiers", force: :cascade do |t|
    t.bigint "bid_increment_schedule_id", null: false
    t.datetime "created_at", null: false
    t.integer "increment_cents", null: false
    t.integer "min_amount_cents", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["bid_increment_schedule_id"], name: "index_bid_increment_tiers_on_bid_increment_schedule_id"
  end

  create_table "bids", force: :cascade do |t|
    t.integer "amount_cents", null: false
    t.bigint "auction_listing_id", null: false
    t.bigint "auction_registration_id", null: false
    t.datetime "created_at", null: false
    t.string "state", default: "placed", null: false
    t.datetime "updated_at", null: false
    t.index ["auction_listing_id"], name: "index_bids_on_auction_listing_id"
    t.index ["auction_registration_id"], name: "index_bids_on_auction_registration_id"
  end

  create_table "cart_items", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "guest_cart_token"
    t.bigint "invoice_item_id"
    t.bigint "listing_id", null: false
    t.integer "quantity", default: 1, null: false
    t.datetime "rental_end_at"
    t.integer "rental_price_cents"
    t.datetime "rental_start_at"
    t.bigint "tenant_id", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id"
    t.bigint "variant_id"
    t.index ["guest_cart_token", "listing_id", "variant_id"], name: "index_cart_items_unique_guest_listing_variant", unique: true, where: "((guest_cart_token IS NOT NULL) AND (rental_start_at IS NULL))"
    t.index ["guest_cart_token"], name: "index_cart_items_on_guest_cart_token"
    t.index ["invoice_item_id"], name: "index_cart_items_on_invoice_item_id_unique", unique: true, where: "(invoice_item_id IS NOT NULL)"
    t.index ["listing_id"], name: "index_cart_items_on_listing_id"
    t.index ["tenant_id"], name: "index_cart_items_on_tenant_id"
    t.index ["user_id", "listing_id", "variant_id"], name: "index_cart_items_unique_user_listing_variant", unique: true, where: "((user_id IS NOT NULL) AND (rental_start_at IS NULL) AND (invoice_item_id IS NULL))"
    t.index ["variant_id"], name: "index_cart_items_on_variant_id"
  end

  create_table "check_ins", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "guest_name"
    t.bigint "location_id", null: false
    t.bigint "tenant_id", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id"
    t.index ["location_id", "created_at"], name: "index_check_ins_on_location_id_and_created_at"
    t.index ["tenant_id"], name: "index_check_ins_on_tenant_id"
    t.index ["user_id", "location_id"], name: "index_check_ins_on_user_id_and_location_id"
    t.check_constraint "user_id IS NOT NULL OR guest_name IS NOT NULL", name: "check_ins_user_or_guest_name_present"
  end

  create_table "delivery_methods", force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.boolean "address_required", default: true, null: false
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
    t.index ["key"], name: "index_discount_codes_on_key"
    t.check_constraint "amount_cents > 0", name: "discount_codes_amount_cents_positive"
  end

  create_table "invoice_items", force: :cascade do |t|
    t.integer "amount_cents", null: false
    t.datetime "created_at", null: false
    t.bigint "invoice_id", null: false
    t.bigint "listing_id"
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.index ["invoice_id"], name: "index_invoice_items_on_invoice_id"
    t.index ["listing_id"], name: "index_invoice_items_on_listing_id"
  end

  create_table "invoices", force: :cascade do |t|
    t.bigint "auction_id"
    t.text "charge_error"
    t.datetime "created_at", null: false
    t.string "number", null: false
    t.bigint "offer_id"
    t.string "square_payment_id"
    t.enum "status", default: "unpaid", null: false, enum_type: "invoice_status"
    t.bigint "tenant_id", null: false
    t.integer "total_cents", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["auction_id"], name: "index_invoices_on_auction_id"
    t.index ["number"], name: "index_invoices_on_number", unique: true
    t.index ["offer_id"], name: "index_invoices_on_offer_id_unique", unique: true
    t.index ["tenant_id"], name: "index_invoices_on_tenant_id"
    t.index ["user_id"], name: "index_invoices_on_user_id"
  end

  create_table "listing_inference_batches", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "error_message"
    t.integer "failed_count", default: 0, null: false
    t.string "hashid", null: false
    t.bigint "lot_id", null: false
    t.integer "processed_count", default: 0, null: false
    t.string "status", default: "pending", null: false
    t.bigint "tenant_id", null: false
    t.integer "total_count", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["hashid"], name: "index_listing_inference_batches_on_hashid", unique: true
    t.index ["lot_id"], name: "index_listing_inference_batches_on_lot_id"
    t.index ["tenant_id"], name: "index_listing_inference_batches_on_tenant_id"
  end

  create_table "listings", force: :cascade do |t|
    t.integer "acquisition_price_cents"
    t.datetime "created_at", null: false
    t.bigint "delivery_method_set_id"
    t.string "hashid", null: false
    t.enum "listing_type", default: "sale", null: false, enum_type: "listing_type"
    t.bigint "lot_id"
    t.string "name", null: false
    t.bigint "owner_id"
    t.boolean "physical", default: false, null: false
    t.integer "position", null: false
    t.integer "price_cents", null: false
    t.enum "pricing_type", default: "firm", null: false, enum_type: "listing_pricing_type"
    t.boolean "published", default: false, null: false
    t.integer "quantity", default: 1, null: false
    t.boolean "show_video_as_poster", default: false, null: false
    t.string "sku"
    t.enum "state", default: "on_sale", null: false, enum_type: "listing_state"
    t.boolean "tax_exempt", default: false, null: false
    t.bigint "tenant_id", null: false
    t.datetime "updated_at", null: false
    t.index ["delivery_method_set_id"], name: "index_listings_on_delivery_method_set_id"
    t.index ["hashid"], name: "index_listings_on_hashid", unique: true
    t.index ["lot_id"], name: "index_listings_on_lot_id"
    t.index ["owner_id"], name: "index_listings_on_owner_id"
    t.check_constraint "acquisition_price_cents >= 0", name: "listings_acquisition_price_cents_non_negative"
    t.check_constraint "owner_id IS NOT NULL OR lot_id IS NOT NULL", name: "listings_owner_or_lot_present"
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

  create_table "listings_deliveries", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "delivery_method_id", null: false
    t.bigint "delivery_method_set_id", null: false
    t.bigint "tenant_id", null: false
    t.datetime "updated_at", null: false
    t.index ["delivery_method_id"], name: "index_listings_deliveries_on_delivery_method_id"
    t.index ["delivery_method_set_id", "delivery_method_id"], name: "index_listings_deliveries_unique", unique: true
    t.index ["tenant_id"], name: "index_listings_deliveries_on_tenant_id"
  end

  create_table "listings_delivery_method_sets", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "tenant_id", null: false
    t.datetime "updated_at", null: false
    t.index ["tenant_id"], name: "index_listings_delivery_method_sets_on_tenant_id"
  end

  create_table "listings_option_values", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "option_id", null: false
    t.integer "position", default: 0, null: false
    t.datetime "updated_at", null: false
    t.string "value", null: false
    t.index ["option_id"], name: "index_listings_option_values_on_option_id"
  end

  create_table "listings_options", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "listing_id", null: false
    t.string "name", null: false
    t.integer "position", default: 0, null: false
    t.bigint "tenant_id", null: false
    t.datetime "updated_at", null: false
    t.index ["listing_id"], name: "index_listings_options_on_listing_id"
    t.index ["tenant_id"], name: "index_listings_options_on_tenant_id"
  end

  create_table "listings_properties", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "icon"
    t.bigint "listing_id"
    t.string "name", null: false
    t.integer "position", default: 0, null: false
    t.bigint "property_set_id"
    t.bigint "tenant_id", null: false
    t.datetime "updated_at", null: false
    t.string "value", null: false
    t.index ["listing_id", "position"], name: "index_listings_properties_on_listing_id_and_position"
    t.index ["property_set_id"], name: "index_listings_properties_on_property_set_id"
    t.index ["tenant_id"], name: "index_listings_properties_on_tenant_id"
  end

  create_table "listings_property_sets", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "tenant_id", null: false
    t.datetime "updated_at", null: false
    t.index ["tenant_id"], name: "index_listings_property_sets_on_tenant_id"
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

  create_table "listings_variant_option_values", force: :cascade do |t|
    t.bigint "option_value_id", null: false
    t.bigint "variant_id", null: false
    t.index ["option_value_id"], name: "index_listings_variant_option_values_on_option_value_id"
    t.index ["variant_id", "option_value_id"], name: "idx_on_variant_id_option_value_id_7c0293e78f", unique: true
  end

  create_table "listings_variants", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "listing_id", null: false
    t.integer "price_cents"
    t.integer "quantity", default: 0, null: false
    t.string "sku"
    t.bigint "tenant_id", null: false
    t.datetime "updated_at", null: false
    t.index ["listing_id"], name: "index_listings_variants_on_listing_id"
    t.index ["tenant_id"], name: "index_listings_variants_on_tenant_id"
  end

  create_table "locations", force: :cascade do |t|
    t.float "background_tint_opacity", default: 0.5, null: false
    t.string "checkin_exit_url"
    t.datetime "created_at", null: false
    t.string "hashid", null: false
    t.string "ical_url"
    t.string "name", null: false
    t.boolean "published", default: false, null: false
    t.bigint "tenant_id", null: false
    t.datetime "updated_at", null: false
    t.index ["hashid"], name: "index_locations_on_hashid", unique: true
    t.index ["tenant_id", "name"], name: "index_locations_on_tenant_id_and_name"
  end

  create_table "lots", force: :cascade do |t|
    t.text "admin_notes"
    t.integer "commission_rate"
    t.datetime "created_at", null: false
    t.string "hashid", null: false
    t.string "name", null: false
    t.string "number"
    t.bigint "owner_id", null: false
    t.datetime "paid_at"
    t.integer "payout_amount_cents"
    t.integer "seller_fee_cents"
    t.datetime "settled_at"
    t.boolean "show_attribution", default: false, null: false
    t.enum "state", default: "submitted", null: false, enum_type: "lot_state"
    t.bigint "tenant_id", null: false
    t.datetime "updated_at", null: false
    t.index ["hashid"], name: "index_lots_on_hashid", unique: true
    t.index ["owner_id"], name: "index_lots_on_owner_id"
    t.index ["tenant_id"], name: "index_lots_on_tenant_id"
  end

  create_table "oauth_identities", force: :cascade do |t|
    t.text "access_token"
    t.datetime "created_at", null: false
    t.string "email"
    t.string "name_from_provider"
    t.string "provider", null: false
    t.text "refresh_token"
    t.bigint "tenant_id", null: false
    t.datetime "token_expires_at"
    t.string "uid", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["provider", "uid"], name: "index_oauth_identities_on_provider_and_uid", unique: true
    t.index ["tenant_id"], name: "index_oauth_identities_on_tenant_id"
    t.index ["user_id"], name: "index_oauth_identities_on_user_id"
  end

  create_table "offers", force: :cascade do |t|
    t.integer "amount_cents", null: false
    t.datetime "created_at", null: false
    t.string "guest_email"
    t.string "guest_name"
    t.string "guest_phone"
    t.bigint "listing_id", null: false
    t.string "message"
    t.enum "state", default: "pending", null: false, enum_type: "offer_state"
    t.bigint "tenant_id", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id"
    t.index ["listing_id"], name: "index_offers_on_listing_id"
    t.index ["listing_id"], name: "index_offers_on_listing_id_where_accepted", unique: true, where: "(state = 'accepted'::offer_state)"
    t.index ["tenant_id"], name: "index_offers_on_tenant_id"
    t.index ["user_id"], name: "index_offers_on_user_id"
    t.check_constraint "amount_cents > 0", name: "offers_amount_cents_positive"
  end

  create_table "order_items", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "listing_id"
    t.string "listing_type"
    t.string "name", null: false
    t.bigint "order_id", null: false
    t.integer "price_cents", null: false
    t.datetime "rental_end_at"
    t.datetime "rental_start_at"
    t.datetime "updated_at", null: false
    t.string "variant_name"
    t.index ["listing_id"], name: "index_order_items_on_listing_id"
    t.index ["order_id"], name: "index_order_items_on_order_id"
  end

  create_table "orders", force: :cascade do |t|
    t.string "admin_notes"
    t.string "city"
    t.string "country"
    t.datetime "created_at", null: false
    t.bigint "delivery_method_id"
    t.string "delivery_method_name"
    t.integer "delivery_price_cents", default: 0, null: false
    t.integer "discount_cents", default: 0, null: false
    t.bigint "discount_code_id"
    t.string "discount_code_key"
    t.string "guest_email"
    t.string "guest_name"
    t.string "guest_token"
    t.string "number", null: false
    t.string "postal_code"
    t.string "province"
    t.string "square_payment_id"
    t.string "status", default: "pending", null: false
    t.string "street_address"
    t.integer "subtotal_cents", null: false
    t.integer "tax_cents", null: false
    t.bigint "tenant_id", null: false
    t.integer "total_cents", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id"
    t.index ["delivery_method_id"], name: "index_orders_on_delivery_method_id"
    t.index ["discount_code_id"], name: "index_orders_on_discount_code_id"
    t.index ["guest_token"], name: "index_orders_on_guest_token", unique: true
    t.index ["number"], name: "index_orders_on_number", unique: true
    t.index ["square_payment_id"], name: "index_orders_on_square_payment_id", unique: true
    t.index ["tenant_id"], name: "index_orders_on_tenant_id"
    t.index ["user_id"], name: "index_orders_on_user_id"
  end

  create_table "pages", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "icon"
    t.text "meta_description"
    t.string "meta_title"
    t.integer "position", default: 0, null: false
    t.boolean "published", default: false, null: false
    t.boolean "show_in_footer", default: false, null: false
    t.boolean "show_in_nav", default: false, null: false
    t.string "slug", null: false
    t.bigint "tenant_id", null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.index ["tenant_id", "slug"], name: "index_pages_on_tenant_id_and_slug", unique: true
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

  create_table "proxy_bids", force: :cascade do |t|
    t.bigint "auction_listing_id", null: false
    t.bigint "auction_registration_id", null: false
    t.datetime "created_at", null: false
    t.integer "max_bid_cents", null: false
    t.datetime "updated_at", null: false
    t.index ["auction_listing_id", "auction_registration_id"], name: "index_proxy_bids_on_listing_and_registration", unique: true
    t.index ["auction_registration_id"], name: "index_proxy_bids_on_auction_registration_id"
  end

  create_table "qr_codes", force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.text "destination_url", null: false
    t.datetime "expires_at"
    t.text "inactive_url"
    t.datetime "last_scanned_at"
    t.bigint "location_id"
    t.string "name", null: false
    t.text "notes"
    t.bigint "notify_user_id"
    t.bigint "owner_id"
    t.integer "scan_count", default: 0, null: false
    t.string "slug", null: false
    t.bigint "tenant_id", null: false
    t.datetime "updated_at", null: false
    t.index ["location_id"], name: "index_qr_codes_on_location_id", unique: true
    t.index ["notify_user_id"], name: "index_qr_codes_on_notify_user_id"
    t.index ["owner_id"], name: "index_qr_codes_on_owner_id"
    t.index ["tenant_id", "slug"], name: "index_qr_codes_on_tenant_id_and_slug", unique: true
  end

  create_table "qr_scans", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "ip_address"
    t.bigint "qr_code_id", null: false
    t.datetime "updated_at", null: false
    t.string "user_agent"
    t.index ["qr_code_id"], name: "index_qr_scans_on_qr_code_id"
  end

  create_table "rental_bookings", force: :cascade do |t|
    t.bigint "cart_item_id"
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

  create_table "settlement_line_items", force: :cascade do |t|
    t.integer "amount_cents", null: false
    t.datetime "created_at", null: false
    t.string "description", null: false
    t.enum "line_item_type", null: false, enum_type: "settlement_line_item_type"
    t.bigint "listing_id"
    t.bigint "settlement_id", null: false
    t.bigint "tenant_id", null: false
    t.datetime "updated_at", null: false
    t.index ["listing_id"], name: "index_settlement_line_items_on_listing_id"
    t.index ["settlement_id"], name: "index_settlement_line_items_on_settlement_id"
    t.index ["tenant_id"], name: "index_settlement_line_items_on_tenant_id"
  end

  create_table "settlements", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "lot_id", null: false
    t.bigint "tenant_id", null: false
    t.datetime "updated_at", null: false
    t.index ["lot_id"], name: "index_settlements_on_lot_id", unique: true
    t.index ["tenant_id"], name: "index_settlements_on_tenant_id"
  end

  create_table "social_media_accounts", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "icon", null: false
    t.enum "platform", null: false, enum_type: "social_media_platform"
    t.integer "position", default: 0, null: false
    t.string "slug", null: false
    t.bigint "tenant_id", null: false
    t.datetime "updated_at", null: false
    t.index ["tenant_id", "platform"], name: "index_social_media_accounts_on_tenant_id_and_platform", unique: true
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
    t.string "background_color"
    t.string "card_color"
    t.string "container_color"
    t.datetime "created_at", null: false
    t.string "currency", default: "CAD", null: false
    t.string "custom_domain"
    t.boolean "default", default: false, null: false
    t.bigint "default_delivery_method_set_id"
    t.string "email_address"
    t.jsonb "features", default: {}, null: false
    t.string "footer_color"
    t.string "key", null: false
    t.string "link_color"
    t.string "name", null: false
    t.string "phone_number"
    t.string "primary_color"
    t.string "secondary_color"
    t.string "tagline"
    t.string "tertiary_color"
    t.string "text_color"
    t.string "timezone"
    t.datetime "updated_at", null: false
    t.index ["default"], name: "index_tenants_on_default_true", unique: true, where: "(\"default\" = true)"
    t.index ["default_delivery_method_set_id"], name: "index_tenants_on_default_delivery_method_set_id"
    t.index ["key"], name: "index_tenants_on_key", unique: true
  end

  create_table "transactions", force: :cascade do |t|
    t.integer "amount_cents", null: false
    t.datetime "created_at", null: false
    t.text "error_message"
    t.bigint "order_id", null: false
    t.jsonb "raw_response"
    t.string "square_payment_id"
    t.enum "state", default: "pending", null: false, enum_type: "transaction_state"
    t.datetime "updated_at", null: false
    t.uuid "uuid", null: false
    t.index ["order_id"], name: "index_transactions_on_order_id"
    t.index ["order_id"], name: "index_transactions_on_order_id_succeeded", unique: true, where: "(state = 'succeeded'::transaction_state)"
    t.index ["uuid"], name: "index_transactions_on_uuid", unique: true
  end

  create_table "user_category_interests", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "listings_category_id", null: false
    t.bigint "tenant_id", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["listings_category_id"], name: "index_user_category_interests_on_listings_category_id"
    t.index ["tenant_id"], name: "index_user_category_interests_on_tenant_id"
    t.index ["user_id", "listings_category_id"], name: "idx_on_user_id_listings_category_id_ec5a7d89e4", unique: true
  end

  create_table "users", force: :cascade do |t|
    t.datetime "activated_at"
    t.datetime "created_at", null: false
    t.string "default_square_card_id"
    t.string "email_address", null: false
    t.string "first_name", null: false
    t.string "last_name", null: false
    t.string "password_digest", null: false
    t.bigint "role_id"
    t.string "square_customer_id"
    t.bigint "tenant_id", null: false
    t.datetime "updated_at", null: false
    t.index "lower((email_address)::text)", name: "index_users_on_lower_email_address", unique: true
    t.index ["email_address"], name: "index_users_on_email_address"
    t.index ["role_id"], name: "index_users_on_role_id"
    t.index ["tenant_id"], name: "index_users_on_tenant_id"
  end

  create_table "users_verifications", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.enum "status", default: "not_validated", null: false, enum_type: "user_verification_status"
    t.bigint "tenant_id", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.bigint "validated_by_id"
    t.index ["tenant_id"], name: "index_users_verifications_on_tenant_id"
    t.index ["user_id"], name: "index_users_verifications_on_user_id", unique: true
  end

  create_table "watchlist_items", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "listing_id", null: false
    t.bigint "tenant_id", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["listing_id"], name: "index_watchlist_items_on_listing_id"
    t.index ["tenant_id"], name: "index_watchlist_items_on_tenant_id"
    t.index ["user_id", "listing_id"], name: "index_watchlist_items_on_user_id_and_listing_id", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "auction_listings", "auctions"
  add_foreign_key "auction_listings", "listings"
  add_foreign_key "auction_listings", "listings_variants", column: "variant_id", on_delete: :cascade
  add_foreign_key "auction_registrations", "auctions"
  add_foreign_key "auction_registrations", "tenants"
  add_foreign_key "auction_registrations", "users"
  add_foreign_key "auctions", "tenants"
  add_foreign_key "bid_increment_schedules", "auctions", on_delete: :cascade
  add_foreign_key "bid_increment_schedules", "tenants"
  add_foreign_key "bid_increment_tiers", "bid_increment_schedules", on_delete: :cascade
  add_foreign_key "bids", "auction_listings"
  add_foreign_key "bids", "auction_registrations"
  add_foreign_key "cart_items", "invoice_items", on_delete: :nullify
  add_foreign_key "cart_items", "listings"
  add_foreign_key "cart_items", "listings_variants", column: "variant_id", on_delete: :nullify
  add_foreign_key "cart_items", "tenants"
  add_foreign_key "cart_items", "users"
  add_foreign_key "check_ins", "locations"
  add_foreign_key "check_ins", "tenants", on_delete: :cascade
  add_foreign_key "check_ins", "users"
  add_foreign_key "delivery_methods", "tenants"
  add_foreign_key "discount_codes", "tenants"
  add_foreign_key "invoice_items", "invoices"
  add_foreign_key "invoice_items", "listings", on_delete: :nullify
  add_foreign_key "invoices", "auctions"
  add_foreign_key "invoices", "offers", on_delete: :nullify
  add_foreign_key "invoices", "tenants"
  add_foreign_key "invoices", "users"
  add_foreign_key "listing_inference_batches", "lots"
  add_foreign_key "listing_inference_batches", "tenants", on_delete: :cascade
  add_foreign_key "listings", "listings_delivery_method_sets", column: "delivery_method_set_id", on_delete: :nullify, validate: false
  add_foreign_key "listings", "lots", on_delete: :cascade
  add_foreign_key "listings", "tenants"
  add_foreign_key "listings", "users", column: "owner_id"
  add_foreign_key "listings_categories", "tenants"
  add_foreign_key "listings_category_assignments", "listings"
  add_foreign_key "listings_category_assignments", "listings_categories"
  add_foreign_key "listings_deliveries", "delivery_methods", on_delete: :cascade
  add_foreign_key "listings_deliveries", "listings_delivery_method_sets", column: "delivery_method_set_id", on_delete: :cascade
  add_foreign_key "listings_deliveries", "tenants", on_delete: :cascade
  add_foreign_key "listings_delivery_method_sets", "tenants", on_delete: :cascade
  add_foreign_key "listings_option_values", "listings_options", column: "option_id"
  add_foreign_key "listings_options", "listings"
  add_foreign_key "listings_options", "tenants", on_delete: :cascade
  add_foreign_key "listings_properties", "listings"
  add_foreign_key "listings_properties", "listings_property_sets", column: "property_set_id"
  add_foreign_key "listings_properties", "tenants", on_delete: :cascade
  add_foreign_key "listings_property_sets", "tenants"
  add_foreign_key "listings_rental_rate_plans", "listings"
  add_foreign_key "listings_rental_rate_plans", "tenants"
  add_foreign_key "listings_variant_option_values", "listings_option_values", column: "option_value_id"
  add_foreign_key "listings_variant_option_values", "listings_variants", column: "variant_id"
  add_foreign_key "listings_variants", "listings"
  add_foreign_key "listings_variants", "tenants", on_delete: :cascade
  add_foreign_key "locations", "tenants", on_delete: :cascade
  add_foreign_key "lots", "tenants"
  add_foreign_key "lots", "users", column: "owner_id"
  add_foreign_key "oauth_identities", "tenants"
  add_foreign_key "oauth_identities", "users"
  add_foreign_key "offers", "listings"
  add_foreign_key "offers", "tenants"
  add_foreign_key "offers", "users"
  add_foreign_key "order_items", "listings", on_delete: :nullify
  add_foreign_key "order_items", "orders"
  add_foreign_key "orders", "delivery_methods", on_delete: :nullify
  add_foreign_key "orders", "discount_codes", on_delete: :nullify
  add_foreign_key "orders", "tenants"
  add_foreign_key "orders", "users"
  add_foreign_key "pages", "tenants", on_delete: :cascade
  add_foreign_key "permissions", "roles"
  add_foreign_key "permissions", "tenants"
  add_foreign_key "proxy_bids", "auction_listings"
  add_foreign_key "proxy_bids", "auction_registrations"
  add_foreign_key "qr_codes", "locations", validate: false
  add_foreign_key "qr_codes", "tenants"
  add_foreign_key "qr_codes", "users", column: "notify_user_id", validate: false
  add_foreign_key "qr_codes", "users", column: "owner_id", on_delete: :nullify
  add_foreign_key "qr_scans", "qr_codes"
  add_foreign_key "rental_bookings", "cart_items", on_delete: :nullify, validate: false
  add_foreign_key "rental_bookings", "listings"
  add_foreign_key "rental_bookings", "tenants"
  add_foreign_key "roles", "tenants"
  add_foreign_key "sessions", "users"
  add_foreign_key "settlement_line_items", "listings", on_delete: :nullify
  add_foreign_key "settlement_line_items", "settlements", on_delete: :cascade
  add_foreign_key "settlement_line_items", "tenants", on_delete: :cascade
  add_foreign_key "settlements", "lots", on_delete: :cascade
  add_foreign_key "settlements", "tenants", on_delete: :cascade
  add_foreign_key "social_media_accounts", "tenants"
  add_foreign_key "solid_queue_blocked_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_claimed_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_failed_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_ready_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_recurring_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_scheduled_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "tenants", "listings_delivery_method_sets", column: "default_delivery_method_set_id", on_delete: :nullify
  add_foreign_key "transactions", "orders"
  add_foreign_key "user_category_interests", "listings_categories"
  add_foreign_key "user_category_interests", "tenants", on_delete: :cascade
  add_foreign_key "user_category_interests", "users"
  add_foreign_key "users", "roles"
  add_foreign_key "users", "tenants"
  add_foreign_key "users_verifications", "tenants", on_delete: :cascade
  add_foreign_key "users_verifications", "users"
  add_foreign_key "users_verifications", "users", column: "validated_by_id"
  add_foreign_key "watchlist_items", "listings"
  add_foreign_key "watchlist_items", "tenants", on_delete: :cascade
  add_foreign_key "watchlist_items", "users"

  create_function :notify_bid_event, sql_definition: <<-'SQL'
      CREATE OR REPLACE FUNCTION public.notify_bid_event()
       RETURNS trigger
       LANGUAGE plpgsql
      AS $function$
      BEGIN
        PERFORM pg_notify(
          'bid_events',
          json_build_object(
            'bid_id',                  NEW.id,
            'auction_listing_id',      NEW.auction_listing_id,
            'auction_registration_id', NEW.auction_registration_id,
            'amount_cents',            NEW.amount_cents,
            'state',                   NEW.state
          )::text
        );
        RETURN NEW;
      END;
      $function$
  SQL

  create_trigger :bid_event_trigger, sql_definition: <<-SQL
      CREATE TRIGGER bid_event_trigger AFTER INSERT OR UPDATE ON public.bids FOR EACH ROW EXECUTE FUNCTION notify_bid_event()
  SQL
end
