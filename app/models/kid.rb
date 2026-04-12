class Kid < ApplicationRecord
  include MultiTenant

  belongs_to :user

  validates :name, presence: true
  validates :birthdate, presence: true
end
