class Role < ApplicationRecord
  has_many :users, dependent: :nullify

  validates :name, presence: true, uniqueness: { case_sensitive: false }
  validates :description, presence: true
end
