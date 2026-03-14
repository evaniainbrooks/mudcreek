class Listings::Delivery < ApplicationRecord
  include MultiTenant

  belongs_to :delivery_method_set, class_name: "Listings::DeliveryMethodSet"
  belongs_to :delivery_method
end
