class Kid < ApplicationRecord
  include MultiTenant

  belongs_to :user
  has_many :rank_awards, as: :rankable, dependent: :destroy

  validates :name, presence: true
  validates :birthdate, presence: true

  def self.ransackable_attributes(_auth_object = nil)
    %w[name]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[user]
  end
end
