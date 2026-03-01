class CartAddressesController < ApplicationController
  def create
    attrs = params.require(:cart_address).permit(
      :street_address, :city, :province, :postal_code, :country
    )

    cart_address = Current.user.cart_address || Current.user.build_cart_address
    cart_address.update!(attrs)

    if params[:cart_address][:also_save_as_default] == "1"
      profile_address = Current.user.address || Current.user.build_address
      profile_address.update!(attrs)
    end

    redirect_to cart_path, notice: "Delivery address saved."
  end
end
