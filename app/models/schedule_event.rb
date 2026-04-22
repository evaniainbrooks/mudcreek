class ScheduleEvent < ApplicationRecord
  include MultiTenant

  belongs_to :schedule

  has_one_attached :photo

  scope :ordered, -> { order(:starts_at) }
end
