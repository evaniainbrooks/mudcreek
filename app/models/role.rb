class Role < ApplicationRecord
  has_many :users, dependent: :restrict_with_error
  has_many :permissions, dependent: :destroy

  validates :name, presence: true, uniqueness: { case_sensitive: false }, format: { with: /\A[a-z_]+\z/, message: "can only contain lowercase letters and underscores" }
  validates :description, presence: true

  def name
    ActiveSupport::StringInquirer.new(super) if super
  end
end
