class ProfilesController < ApplicationController
  def edit
    @user = Current.user
    @user.build_address unless @user.address
    if Current.tenant.features.ranks?
      @user_ranks_by_discipline = @user.rank_awards.ordered.includes(rank: :discipline).group_by(&:discipline)
    end
  end

  def update
    @user = Current.user
    @user.build_address unless @user.address

    if @user.update(profile_params)
      redirect_to edit_profile_path, notice: "Profile updated successfully."
    else
      render :edit, status: :unprocessable_content
    end
  end

  private

  def profile_params
    params.require(:user).permit(
      :first_name, :last_name, :birthdate,
      address_attributes: [ :street_address, :city, :province, :postal_code, :country ],
      kids_attributes: [ :id, :name, :birthdate, :_destroy ]
    )
  end
end
