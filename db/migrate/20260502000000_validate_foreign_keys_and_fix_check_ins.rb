class ValidateForeignKeysAndFixCheckIns < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def change
    # Validate all deferred FKs so database_consistency recognises on_delete behaviour
    validate_foreign_key :disciplines, :tenants
    validate_foreign_key :ranks, :tenants
    validate_foreign_key :rank_awards, :tenants
    validate_foreign_key :rank_awards, column: :awarded_by_id
    validate_foreign_key :subscription_users, :tenants
    validate_foreign_key :schedule_event_sessions, :tenants
    validate_foreign_key :schedule_event_registrations, :tenants
    validate_foreign_key :schedule_event_registrations, column: :schedule_event_pass_id
    validate_foreign_key :schedule_event_passes, :tenants
    validate_foreign_key :check_ins, :schedule_events
    validate_foreign_key :check_ins, :schedule_event_registrations
    validate_foreign_key :kiosks, :schedules
    validate_foreign_key :kiosks, column: :drop_in_pass_listing_id
    validate_foreign_key :tenants, column: :homepage_page_id
    validate_foreign_key :inquiries, column: :owner_id
    validate_foreign_key :location_announcements, column: :sent_by_id
    validate_foreign_key :listings, :subscription_plans

    # Make check_ins.schedule_event_registration_id unique to back has_one :check_in
    remove_index :check_ins, :schedule_event_registration_id,
      name: :index_check_ins_on_schedule_event_registration_id, if_exists: true
    add_index :check_ins, :schedule_event_registration_id,
      unique: true, algorithm: :concurrently,
      where: "schedule_event_registration_id IS NOT NULL",
      if_not_exists: true
  end
end
