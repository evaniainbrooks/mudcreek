class FixDatabaseConsistency < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def change
    # RedundantIndexChecker: these single-column indexes are covered by the composite unique indexes
    remove_index :ranks, name: :index_ranks_on_discipline_id, if_exists: true
    remove_index :disciplines, name: :index_disciplines_on_tenant_id, if_exists: true

    # MissingIndexChecker: has_one associations need a unique index on the FK column
    remove_index :kiosks, name: :index_kiosks_on_location_id, if_exists: true
    add_index :kiosks, :location_id, unique: true, algorithm: :concurrently, if_not_exists: true

    remove_index :kiosks, name: :index_kiosks_on_schedule_id, if_exists: true
    add_index :kiosks, :schedule_id, unique: true, algorithm: :concurrently, if_not_exists: true

    remove_index :tenants, name: :index_tenants_on_homepage_page_id, if_exists: true
    add_index :tenants, :homepage_page_id, unique: true, algorithm: :concurrently, if_not_exists: true

    # MissingDependentDestroyChecker: add on_delete: :cascade to tenant FKs
    remove_foreign_key :disciplines, :tenants, if_exists: true
    add_foreign_key :disciplines, :tenants, on_delete: :cascade, validate: false

    remove_foreign_key :ranks, :tenants, if_exists: true
    add_foreign_key :ranks, :tenants, on_delete: :cascade, validate: false

    remove_foreign_key :rank_awards, :tenants, if_exists: true
    add_foreign_key :rank_awards, :tenants, on_delete: :cascade, validate: false

    remove_foreign_key :subscription_users, :tenants, if_exists: true
    add_foreign_key :subscription_users, :tenants, on_delete: :cascade, validate: false

    remove_foreign_key :schedule_event_sessions, :tenants, if_exists: true
    add_foreign_key :schedule_event_sessions, :tenants, on_delete: :cascade, validate: false

    remove_foreign_key :schedule_event_registrations, :tenants, if_exists: true
    add_foreign_key :schedule_event_registrations, :tenants, on_delete: :cascade, validate: false

    remove_foreign_key :schedule_event_passes, :tenants, if_exists: true
    add_foreign_key :schedule_event_passes, :tenants, on_delete: :cascade, validate: false

    # ForeignKeyCascadeChecker: has_many/has_one with dependent: :nullify needs matching DB-level on_delete
    remove_foreign_key :check_ins, :schedule_events, if_exists: true
    add_foreign_key :check_ins, :schedule_events, on_delete: :nullify, validate: false

    remove_foreign_key :check_ins, :schedule_event_registrations, if_exists: true
    add_foreign_key :check_ins, :schedule_event_registrations, on_delete: :nullify, validate: false

    remove_foreign_key :schedule_event_registrations, :schedule_event_passes, if_exists: true
    add_foreign_key :schedule_event_registrations, :schedule_event_passes, on_delete: :nullify, validate: false

    remove_foreign_key :kiosks, :schedules, if_exists: true
    add_foreign_key :kiosks, :schedules, on_delete: :nullify, validate: false

    remove_foreign_key :tenants, column: :homepage_page_id, if_exists: true
    add_foreign_key :tenants, :pages, column: :homepage_page_id, on_delete: :nullify, validate: false

    remove_foreign_key :inquiries, column: :owner_id, if_exists: true
    add_foreign_key :inquiries, :users, column: :owner_id, on_delete: :nullify, validate: false

    remove_foreign_key :location_announcements, column: :sent_by_id, if_exists: true
    add_foreign_key :location_announcements, :users, column: :sent_by_id, on_delete: :nullify, validate: false

    remove_foreign_key :rank_awards, column: :awarded_by_id, if_exists: true
    add_foreign_key :rank_awards, :users, column: :awarded_by_id, on_delete: :nullify, validate: false

    remove_foreign_key :kiosks, column: :drop_in_pass_listing_id, if_exists: true
    add_foreign_key :kiosks, :listings, column: :drop_in_pass_listing_id, on_delete: :nullify, validate: false

    remove_foreign_key :listings, :subscription_plans, if_exists: true
    add_foreign_key :listings, :subscription_plans, on_delete: :nullify, validate: false
  end
end
