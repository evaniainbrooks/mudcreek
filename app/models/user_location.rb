class UserLocation < ApplicationRecord
  include MultiTenant

  belongs_to :user
  belongs_to :location
end
