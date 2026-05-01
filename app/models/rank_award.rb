class RankAward < ApplicationRecord
  include MultiTenant

  belongs_to :rankable, polymorphic: true
  belongs_to :rank
  belongs_to :awarded_by, class_name: "User", optional: true

  has_one :discipline, through: :rank

  validates :awarded_at, presence: true
  validates :stripes, inclusion: { in: 0..4 }
  validate :rankable_type_matches_discipline

  scope :ordered, -> { order(awarded_at: :desc, id: :desc) }

  private

  def rankable_type_matches_discipline
    return unless rank&.discipline
    if rank.discipline.kids? && rankable.is_a?(User)
      errors.add(:base, "#{rank.discipline.name} is a kids discipline and cannot be assigned to a user.")
    elsif !rank.discipline.kids? && rankable.is_a?(Kid)
      errors.add(:base, "#{rank.discipline.name} is not a kids discipline and cannot be assigned to a kid.")
    end
  end
end
