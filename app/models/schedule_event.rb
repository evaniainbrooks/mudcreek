class ScheduleEvent < ApplicationRecord
  include MultiTenant

  belongs_to :schedule

  has_one_attached :photo
  has_many :schedule_event_sessions, dependent: :destroy
  has_many :check_ins, dependent: :nullify

  before_validation :assign_uid, on: :create

  validates :uid, presence: true, uniqueness: { scope: :schedule_id }

  scope :ordered,   -> { order(:starts_at) }
  scope :bookable,  -> { where(bookable: true) }

  private

  def assign_uid
    self.uid ||= SecureRandom.uuid
  end
end
