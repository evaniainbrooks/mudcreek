class LocationKiosksController < ApplicationController
  include LocationFeatureGated

  allow_unauthenticated_access
  layout "showroom"

  def show
    @location = Location.find_by!(hashid: params[:location_hashid], published: true)
    @today_events = LocationCalendarService.new(@location).today_events
    kiosk = @location.kiosk
    @birthday_names = kiosk&.member_birthdays? ? kiosk.today_birthday_names : []
  end
end
