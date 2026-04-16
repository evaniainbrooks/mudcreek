class LocationSchedulesController < ApplicationController
  include LocationFeatureGated

  allow_unauthenticated_access

  def show
    @location = if params[:location_hashid] == "DEFAULT"
      Location.find_by!(default: true, published: true)
    else
      Location.find_by!(hashid: params[:location_hashid], published: true)
    end
    @schedule_view = params[:view].presence_in(%w[daily weekly]) || "weekly"
  end
end
