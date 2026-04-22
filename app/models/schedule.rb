class Schedule < ApplicationRecord
  include MultiTenant

  belongs_to :location
  has_many :schedule_events, dependent: :destroy

  scope :ordered, -> { order(:name) }
end
