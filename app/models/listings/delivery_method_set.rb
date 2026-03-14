class Listings::DeliveryMethodSet < ApplicationRecord
  include MultiTenant

  has_many :deliveries, class_name: "Listings::Delivery", foreign_key: :delivery_method_set_id, dependent: :destroy
  has_many :delivery_methods, through: :deliveries

  validates :name, presence: true
end
