class Listings::Option < ApplicationRecord
  include MultiTenant
  self.table_name = "listings_options"

  belongs_to :listing
  has_many :option_values, class_name: "Listings::OptionValue",
           foreign_key: :option_id, dependent: :destroy

  acts_as_list scope: :listing

  before_validation :set_default_position, on: :create

  validates :name, presence: true
  validates :position, presence: true

  accepts_nested_attributes_for :option_values, allow_destroy: true, reject_if: :all_blank

  private

  def set_default_position
    self.position ||= self.class.where(listing_id: listing_id).maximum(:position).to_i + 1
  end
end
