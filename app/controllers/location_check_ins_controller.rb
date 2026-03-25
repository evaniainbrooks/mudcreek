class LocationCheckInsController < ApplicationController
  include LocationFeatureGated

  allow_unauthenticated_access

  before_action :set_location

  def show
    if Current.user
      @check_in = @location.check_ins.build(user: Current.user)
      @check_in.save
    else
      session[:return_to_after_authenticating] = request.url
      @check_in = @location.check_ins.build
    end
  end

  def create
    @check_in = @location.check_ins.build(guest_name: check_in_params[:guest_name])
    if @check_in.save
      redirect_to location_checkin_path(@location), flash: { guest_checked_in: @check_in.guest_name }
    else
      render :show, status: :unprocessable_entity
    end
  end

  private

  def set_location
    @location = Location.find_by!(hashid: params[:location_hashid], published: true)
  end

  def check_in_params
    params.expect(check_in: [:guest_name])
  end
end
