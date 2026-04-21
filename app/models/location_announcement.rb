class LocationAnnouncement < ApplicationRecord
  include MultiTenant

  belongs_to :location
  belongs_to :sent_by, class_name: "User"

  validates :subject, :body, presence: true

  scope :ordered, -> { order(created_at: :desc) }

  def sent? = sent_at.present?
end
