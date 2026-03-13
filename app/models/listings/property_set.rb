class Listings::PropertySet < ApplicationRecord
  include MultiTenant

  has_many :properties, class_name: "Listings::Property", foreign_key: :property_set_id, dependent: :destroy

  validates :name, presence: true
end
