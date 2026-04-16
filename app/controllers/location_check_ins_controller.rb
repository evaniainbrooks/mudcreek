class LocationCheckInsController < ApplicationController
  include LocationFeatureGated

  allow_unauthenticated_access
  layout "checkin"

  before_action :set_location

  def show
    @guest_checked_in = session.delete(:guest_checked_in)
    if Current.user && !bot_request?
      @check_in = @location.check_ins.build(user: Current.user)
      @check_in.save
    elsif Current.user
      @check_in = @location.check_ins.build(user: Current.user)
    else
      session[:return_to_after_authenticating] = request.url
      @check_in = @location.check_ins.build
      @guest_names = CheckIn.where.not(guest_name: nil)
                            .distinct
                            .order(:guest_name)
                            .pluck(:guest_name)
    end
  end

  def create
    return head :ok if bot_request?

    @check_in = @location.check_ins.build(guest_name: check_in_params[:guest_name])
    if @check_in.save
      session[:guest_checked_in] = @check_in.guest_name
      redirect_to location_checkin_path(@location)
    else
      render :show, status: :unprocessable_content
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
