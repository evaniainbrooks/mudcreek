class Kiosk < ApplicationRecord
  include MultiTenant

  belongs_to :location
  belongs_to :schedule, optional: true

  has_one_attached :logo
  has_many_attached :backgrounds
  has_rich_text :message
end
