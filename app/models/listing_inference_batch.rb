class ListingInferenceBatch < ApplicationRecord
  include MultiTenant
  include HasHashid

  belongs_to :lot

  has_many_attached :source_files

  STATUSES = %w[pending processing done failed].freeze

  validates :status, inclusion: { in: STATUSES }
  validates :lot_id, presence: true
  validate :source_files_present

  def name = "batch"

  def pending?    = status == "pending"
  def processing? = status == "processing"
  def done?       = status == "done"
  def failed?     = status == "failed"

  def progress_percent
    return 0 if total_count.zero?
    (processed_count + failed_count).to_f / total_count * 100
  end

  private

  def source_files_present
    errors.add(:source_files, :blank) unless source_files.attached?
  end
end
