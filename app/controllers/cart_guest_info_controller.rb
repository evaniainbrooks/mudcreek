class CartGuestInfoController < ApplicationController
  allow_unauthenticated_access

  def create
    attrs = params.require(:guest_info).permit(:email, :name)
    session[:guest_email] = attrs[:email].strip
    session[:guest_name]  = attrs[:name].strip
    redirect_to cart_path, notice: "Contact information saved."
  end
end
