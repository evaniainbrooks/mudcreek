class LocationSchedulesController < ApplicationController
  include LocationFeatureGated

  allow_unauthenticated_access

  def show
    @location = Location.find_by!(hashid: params[:location_hashid], published: true)
    @schedule_view = params[:view].presence_in(%w[daily weekly]) || "weekly"
  end
end
