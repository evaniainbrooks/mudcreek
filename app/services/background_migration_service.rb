# Copies each Location's legacy `background` (has_one_attached) attachment to the
# new `backgrounds` (has_many_attached) gallery field by re-using the same blob —
# no file data is copied or re-uploaded.
#
# Usage:
#   BackgroundMigrationService.new.run
#   BackgroundMigrationService.new(dry_run: true).run
#
class BackgroundMigrationService
  Result = Data.define(:migrated, :skipped, :errors)

  def initialize(dry_run: false)
    @dry_run = dry_run
  end

  def run
    migrated = 0
    skipped  = 0
    errors   = []

    legacy_attachments.each do |attachment|
      location = attachment.record

      if already_migrated?(location, attachment.blob_id)
        log "SKIP  location=#{location.id} (blob already in backgrounds)"
        skipped += 1
        next
      end

      unless @dry_run
        ActiveStorage::Attachment.create!(
          name:        "backgrounds",
          record_type: "Location",
          record_id:   location.id,
          blob_id:     attachment.blob_id
        )
      end

      log "#{ @dry_run ? 'DRY   ' : 'OK    '}location=#{location.id} blob=#{attachment.blob_id}"
      migrated += 1
    rescue => e
      log "ERROR location=#{location&.id} #{e.message}"
      errors << { location_id: location&.id, message: e.message }
    end

    Result.new(migrated:, skipped:, errors:)
  end

  private

  def legacy_attachments
    ActiveStorage::Attachment
      .where(name: "background", record_type: "Location")
      .includes(:record, :blob)
  end

  def already_migrated?(location, blob_id)
    ActiveStorage::Attachment.exists?(
      name:        "backgrounds",
      record_type: "Location",
      record_id:   location.id,
      blob_id:     blob_id
    )
  end

  def log(msg)
    Rails.logger.info("[BackgroundMigrationService] #{msg}")
    puts "[BackgroundMigrationService] #{msg}"
  end
end
