class ScheduleWidget < Widget
  belongs_to :location

  validates :location_id, presence: true
end
