class ScheduleEvent < ApplicationRecord
  include MultiTenant

  belongs_to :schedule

  has_one_attached :photo

  before_validation :assign_uid, on: :create

  scope :ordered, -> { order(:starts_at) }

  private

  def assign_uid
    self.uid ||= SecureRandom.uuid
  end
end
