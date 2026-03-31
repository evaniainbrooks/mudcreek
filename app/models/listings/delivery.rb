class Listings::Delivery < ApplicationRecord
  include MultiTenant

  belongs_to :delivery_method_set, class_name: "Listings::DeliveryMethodSet"
  belongs_to :delivery_method

  validates :delivery_method_id, uniqueness: { scope: :delivery_method_set_id }
end
