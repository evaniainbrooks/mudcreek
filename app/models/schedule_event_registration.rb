class ScheduleEventRegistration < ApplicationRecord
  include MultiTenant

  belongs_to :user
  belongs_to :schedule_event_session
  belongs_to :schedule_event_pass, optional: true

  has_one :check_in, dependent: :destroy
  accepts_nested_attributes_for :check_in

  enum :status, { confirmed: 0, cancelled: 1 }

  validates :user_id, uniqueness: {
    scope: :schedule_event_session_id,
    conditions: -> { where.not(status: :cancelled) },
    message: "is already registered for this session"
  }

  after_create :deduct_pass_credit, if: -> { confirmed? && schedule_event_pass_id? }
  before_update :return_pass_credit, if: -> { status_changed?(to: "cancelled") && schedule_event_pass_id? }

  scope :confirmed, -> { where(status: :confirmed) }

  private

  def deduct_pass_credit
    schedule_event_pass.decrement!(:credits_remaining)
  end

  def return_pass_credit
    schedule_event_pass.increment!(:credits_remaining)
  end
end
