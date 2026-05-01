class Kiosk < ApplicationRecord
  include MultiTenant

  belongs_to :location
  belongs_to :schedule, optional: true
  belongs_to :drop_in_pass_listing, class_name: "Listing", optional: true

  validates :location_id, uniqueness: true
  validates :schedule_id, uniqueness: true, allow_nil: true

  has_one_attached :logo
  has_many_attached :backgrounds
  has_rich_text :message

  def today_birthday_names
    today = Date.today
    md    = [today.month, today.day]

    member_ids = location.users.pluck(:id)
    return [] if member_ids.empty?

    user_names = User.unscoped
                     .where(id: member_ids)
                     .where("EXTRACT(MONTH FROM birthdate) = ? AND EXTRACT(DAY FROM birthdate) = ?", *md)
                     .pluck(:first_name)

    kid_names  = Kid.unscoped
                    .where(user_id: member_ids)
                    .where("EXTRACT(MONTH FROM birthdate) = ? AND EXTRACT(DAY FROM birthdate) = ?", *md)
                    .pluck(:name)

    (user_names + kid_names).uniq
  end
end
