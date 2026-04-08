class LocationsController < ApplicationController
  include LocationFeatureGated

  allow_unauthenticated_access
  layout "showroom"

  def show
    @location = if params[:hashid] == "DEFAULT"
      Location.find_by!(default: true, published: true)
    else
      Location.find_by!(hashid: params[:hashid], published: true)
    end
    @today_events = LocationCalendarService.new(@location).today_events
  end
end
