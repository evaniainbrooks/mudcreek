class Admin::LocationUsersController < Admin::BaseController
  before_action :set_location

  def create
    @user_location = @location.user_locations.build(user_id: params[:user_id])
    authorize(@user_location)
    @user_location.save
    redirect_to admin_location_path(@location)
  end

  def destroy
    @user_location = @location.user_locations.find(params[:id])
    authorize(@user_location)
    @user_location.destroy!
    redirect_to admin_location_path(@location)
  end

  private

  def set_location
    @location = Location.find_by!(hashid: params[:location_hashid])
  end
end
