class Schedule < ApplicationRecord
  include MultiTenant

  belongs_to :location
  has_many :schedule_events, dependent: :destroy
  has_one :kiosk, dependent: :nullify

  scope :ordered, -> { order(:name) }
end
