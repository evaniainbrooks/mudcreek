class LocationSchedulesController < ApplicationController
  include LocationFeatureGated

  allow_unauthenticated_access

  def show
    @location = Location.find_by!(hashid: params[:location_hashid], published: true)
  end
end
