class ProfilesController < ApplicationController
  def edit
    @user = Current.user
    @user.build_address unless @user.address
    @orders = @user.orders.order(created_at: :desc)
  end

  def update
    @user = Current.user
    @user.build_address unless @user.address

    if @user.update(profile_params)
      redirect_to edit_profile_path, notice: "Profile updated successfully."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def profile_params
    params.require(:user).permit(
      :first_name, :last_name,
      address_attributes: [ :street_address, :city, :province, :postal_code, :country ]
    )
  end
end
