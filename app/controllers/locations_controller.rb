class LocationsController < ApplicationController
  include LocationFeatureGated

  allow_unauthenticated_access
  layout "showroom"

  def show
    @location = Location.find_by!(hashid: params[:hashid], published: true)
    @today_events = LocationCalendarService.new(@location).today_events
  end
end
